# frozen_string_literal: true

require 'spec_helper'
require 'openssl'
require 'ostruct'

RSpec.describe SpreeRazorpay::Gateway do
  let(:gateway) do
    gw = described_class.new
    allow(gw).to receive(:preferred_key_id).and_return('rzp_test_sample123')
    allow(gw).to receive(:preferred_key_secret).and_return('secret_abc_456')
    allow(gw).to receive(:preferred_webhook_secret).and_return('webhook_secret_789')
    allow(gw).to receive(:preferred_auto_capture).and_return(true)
    gw
  end

  let(:cart) { double('Cart', id: 1, number: 'R12345', currency: 'USD', completed?: false) }

  describe '#test_mode?' do
    it 'returns true for rzp_test keys' do
      expect(gateway.test_mode?).to be true
    end

    it 'returns false for rzp_live keys' do
      allow(gateway).to receive(:preferred_key_id).and_return('rzp_live_realprod')
      expect(gateway.test_mode?).to be false
    end
  end

  describe '#parse_webhook_event' do
    let(:secret) { 'webhook_secret_789' }
    let(:body) do
      {
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_capture_test',
              order_id: 'order_session_test',
              amount: 50000,
              status: 'captured'
            }
          }
        }
      }.to_json
    end

    let(:valid_signature) { OpenSSL::HMAC.hexdigest('sha256', secret, body) }

    it 'raises WebhookSignatureError when signature header is missing' do
      expect {
        gateway.parse_webhook_event(body, {})
      }.to raise_error(Spree::PaymentMethod::WebhookSignatureError, 'Missing signature')
    end

    it 'raises WebhookSignatureError when signature is invalid' do
      headers = { 'X-Razorpay-Signature' => 'invalid_signature_hex' }
      expect {
        gateway.parse_webhook_event(body, headers)
      }.to raise_error(Spree::PaymentMethod::WebhookSignatureError, 'Invalid webhook signature')
    end

    it 'raises WebhookSignatureError when webhook payload is malformed JSON' do
      bad_body = 'malformed json {'
      sig = OpenSSL::HMAC.hexdigest('sha256', secret, bad_body)
      expect {
        gateway.parse_webhook_event(bad_body, { 'X-Razorpay-Signature' => sig })
      }.to raise_error(Spree::PaymentMethod::WebhookSignatureError, 'Malformed webhook payload')
    end

    it 'returns nil when event type is unsupported' do
      unsupported_body = { event: 'invoice.paid' }.to_json
      sig = OpenSSL::HMAC.hexdigest('sha256', secret, unsupported_body)
      result = gateway.parse_webhook_event(unsupported_body, { 'X-Razorpay-Signature' => sig })
      expect(result).to be_nil
    end

    it 'returns nil when no matching payment session exists' do
      allow(Spree::PaymentSessions::Razorpay).to receive(:find_by).and_return(nil)
      headers = { 'X-Razorpay-Signature' => valid_signature }
      result = gateway.parse_webhook_event(body, headers)
      expect(result).to be_nil
    end

    it 'returns action and payment_session when valid signature and session found' do
      session = double('PaymentSession', external_id: 'order_session_test', external_data: {})
      allow(session).to receive(:update!) do |args|
        session.external_data.merge!(args[:external_data] || {})
      end
      allow(Spree::PaymentSessions::Razorpay).to receive(:find_by).and_return(session)

      headers = { 'X-Razorpay-Signature' => valid_signature }
      result = gateway.parse_webhook_event(body, headers)

      expect(result[:action]).to eq(:captured)
      expect(result[:payment_session]).to eq(session)
      expect(session.external_data['razorpay_payment_id']).to eq('pay_capture_test')
    end
  end

  describe '#complete_payment_session' do
    let(:session_status) { { current: 'pending' } }
    let(:session) do
      s = double(
        'PaymentSession',
        id: 42,
        external_id: 'order_test_123',
        amount: 100.0,
        currency: 'USD',
        external_data: {},
        completed?: session_status[:current] == 'completed',
        failed?: session_status[:current] == 'failed',
        canceled?: session_status[:current] == 'canceled',
        can_process?: true,
        can_complete?: true,
        can_fail?: true
      )
      allow(s).to receive(:process) { session_status[:current] = 'processing' }
      allow(s).to receive(:complete) { session_status[:current] = 'completed' }
      allow(s).to receive(:fail) { session_status[:current] = 'failed' }
      allow(s).to receive(:settle_payment!)
      allow(s).to receive(:update!) do |attrs|
        s.external_data.merge!(attrs[:external_data] || {})
      end
      s
    end

    let(:payment_id) { 'pay_sample_456' }
    let(:valid_signature) do
      OpenSSL::HMAC.hexdigest('sha256', 'secret_abc_456', "#{session.external_id}|#{payment_id}")
    end

    it 'fails the session when signature does not match' do
      expect(session).to receive(:fail)
      gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_payment_id: payment_id, razorpay_signature: 'invalid_sig' }
      )
    end

    it 'fails the session when payment_id is missing' do
      expect(session).to receive(:fail)
      gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_signature: valid_signature }
      )
    end

    it 'completes the session when signature is valid' do
      expect(session).to receive(:settle_payment!).with(captured: true)
      expect(session).to receive(:complete)

      gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_payment_id: payment_id, razorpay_signature: valid_signature }
      )

      expect(session.external_data['razorpay_payment_id']).to eq(payment_id)
    end

    it 'is idempotent and returns immediately if session already completed' do
      session_status[:current] = 'completed'
      allow(session).to receive(:completed?).and_return(true)
      expect(session).not_to receive(:settle_payment!)

      res = gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_payment_id: payment_id, razorpay_signature: valid_signature }
      )
      expect(res).to eq(session)
    end
  end

  describe '#resolve_razorpay_payment_id' do
    it 'returns the ID directly if it starts with pay_' do
      expect(gateway.resolve_razorpay_payment_id('pay_test123')).to eq('pay_test123')
    end

    it 'extracts razorpay_payment_id from payment metadata if available' do
      payment = double('Spree::Payment', metadata: { 'razorpay_payment_id' => 'pay_meta_123' })
      expect(gateway.resolve_razorpay_payment_id('order_abc', { payment: payment })).to eq('pay_meta_123')
    end
  end

  describe '#credit' do
    let(:fake_client) { double('Client') }
    let(:fake_payment_entity) { double('PaymentEntity') }
    let(:fake_refund_entity) { double('RefundEntity', id: 'rfnd_success_123', status: 'processed', receipt: 'REF999') }

    before do
      allow(gateway).to receive(:client).and_return(fake_client)
    end

    it 'refuses refund when amount exceeds credit_allowed' do
      payment = double('Payment', credit_allowed: 50.0, persisted?: false)
      originator = double('Refund', payment: payment, transaction_id: nil)

      response = gateway.credit(100.0, 'pay_test_overcredit', payment: payment, originator: originator)
      expect(response.success?).to be false
      expect(response.message).to include('exceeds maximum allowed refundable amount')
    end

    it 'returns early if originator already has transaction_id' do
      originator = double('Refund', transaction_id: 'rfnd_already_done_456')
      expect(fake_client).not_to receive(:refund)

      response = gateway.credit(50.0, 'pay_test_idemp', originator: originator)
      expect(response.success?).to be true
      expect(response.authorization).to eq('rfnd_already_done_456')
    end

    it 'passes receipt and sets X-Refund-Idempotency header during refund' do
      originator = double('Refund', id: 12, number: 'REF123', transaction_id: nil)
      payment = double('Payment', id: 99, credit_allowed: 100.0, persisted?: false)

      expect(fake_client).to receive_message_chain(:refund, :create).with(
        hash_including(
          payment_id: 'pay_test_header',
          amount: 5000,
          receipt: 'REF123',
          notes: hash_including(spree_payment_id: 99, spree_refund_id: 12)
        )
      ) do
        expect(Razorpay.custom_headers['X-Refund-Idempotency']).to eq('rfnd_pay_test_header_REF123')
        fake_refund_entity
      end

      response = gateway.credit(50.0, 'pay_test_header', payment: payment, originator: originator)
      expect(response.success?).to be true
      expect(response.authorization).to eq('rfnd_success_123')
      expect(Razorpay.custom_headers).to be_nil
    end

    it 'reconciles refund when timeout occurs but Razorpay created the refund' do
      originator = double('Refund', id: 999, number: 'REF999', transaction_id: nil)
      payment = double('Payment', id: 1, credit_allowed: 100.0, persisted?: false)

      allow(fake_client).to receive_message_chain(:refund, :create).and_raise(Timeout::Error.new('execution expired'))
      allow(fake_client).to receive_message_chain(:payment, :fetch).and_return(fake_payment_entity)
      allow(fake_payment_entity).to receive(:refunds).and_return(double('List', items: [fake_refund_entity]))

      response = gateway.credit(50.0, 'pay_test_timeout', payment: payment, originator: originator)
      expect(response.success?).to be true
      expect(response.authorization).to eq('rfnd_success_123')
    end

    it 'reconciles refund when Razorpay returns Duplicate receipt error' do
      originator = double('Refund', id: 999, number: 'REF999', transaction_id: nil)
      payment = double('Payment', id: 1, credit_allowed: 100.0, persisted?: false)

      allow(fake_client).to receive_message_chain(:refund, :create).and_raise(StandardError.new('Duplicate receipt found for this refund request'))
      allow(fake_client).to receive_message_chain(:payment, :fetch).and_return(fake_payment_entity)
      allow(fake_payment_entity).to receive(:refunds).and_return(double('List', items: [fake_refund_entity]))

      response = gateway.credit(50.0, 'pay_test_duplicate', payment: payment, originator: originator)
      expect(response.success?).to be true
      expect(response.authorization).to eq('rfnd_success_123')
    end
  end
end
