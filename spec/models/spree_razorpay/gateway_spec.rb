# frozen_string_literal: true

require 'spec_helper'
require 'openssl'
require 'ostruct'

# Load extension files for standalone testing
require_relative '../../app/services/spree_razorpay/client'

module Spree
  class Gateway
    def self.preference(name, type, options = {}); end
    def self.validates(*args); end
    def self.validate(*args); end
    def self.accepts_money_amounts=(val); end
  end

  class PaymentSession
    def self.delegate(*args); end
    attr_accessor :external_id, :external_data, :status, :amount, :currency, :payment_method, :owner
    def initialize(attrs = {})
      attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
      @external_data ||= {}
    end
    def completed?; status == 'completed'; end
    def failed?; status == 'failed'; end
    def canceled?; status == 'canceled'; end
    def pending?; status == 'pending'; end
    def can_process?; status == 'pending'; end
    def can_complete?; status == 'processing' || status == 'pending'; end
    def can_fail?; true; end
    def can_cancel?; true; end
    def process; self.status = 'processing'; end
    def complete; self.status = 'completed'; end
    def fail; self.status = 'failed'; end
    def cancel; self.status = 'canceled'; end
    def update!(attrs)
      attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
    end
    def settle_payment!(captured: true); end
    def skip_source_requirement(p); p; end
  end

  module PaymentSessions
    class Razorpay < PaymentSession
      def razorpay_order_id; external_id; end
      def razorpay_payment_id; external_data&.dig('razorpay_payment_id'); end
    end
  end

  module PaymentMethod
    class WebhookSignatureError < StandardError; end
  end

  class PaymentResponse
    attr_reader :success, :message, :params, :authorization
    def initialize(success, message = nil, params = {}, authorization: nil)
      @success = success
      @message = message
      @params = params
      @authorization = authorization
    end
    def success?; @success; end
  end

  module Core
    class GatewayError < StandardError; end
  end
end

require_relative '../../app/models/spree_razorpay/gateway/webhooks'
require_relative '../../app/models/spree_razorpay/gateway/payment_sessions'
require_relative '../../app/models/spree_razorpay/gateway'

RSpec.describe SpreeRazorpay::Gateway do
  let(:gateway) do
    gw = described_class.new
    allow(gw).to receive(:preferred_key_id).and_return('rzp_test_sample123')
    allow(gw).to receive(:preferred_key_secret).and_return('secret_abc_456')
    allow(gw).to receive(:preferred_webhook_secret).and_return('webhook_secret_789')
    allow(gw).to receive(:preferred_auto_capture).and_return(true)
    gw
  end

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
      session = Spree::PaymentSessions::Razorpay.new(external_id: 'order_session_test')
      allow(Spree::PaymentSessions::Razorpay).to receive(:find_by).and_return(session)

      headers = { 'X-Razorpay-Signature' => valid_signature }
      result = gateway.parse_webhook_event(body, headers)

      expect(result[:action]).to eq(:captured)
      expect(result[:payment_session]).to eq(session)
      expect(session.external_data['razorpay_payment_id']).to eq('pay_capture_test')
    end
  end

  describe '#complete_payment_session' do
    let(:session) do
      Spree::PaymentSessions::Razorpay.new(
        external_id: 'order_test_123',
        status: 'pending',
        amount: 100.0
      )
    end

    let(:payment_id) { 'pay_sample_456' }
    let(:valid_signature) do
      OpenSSL::HMAC.hexdigest('sha256', 'secret_abc_456', "#{session.external_id}|#{payment_id}")
    end

    it 'fails the session when signature does not match' do
      gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_payment_id: payment_id, razorpay_signature: 'invalid_sig' }
      )
      expect(session.failed?).to be true
    end

    it 'fails the session when payment_id is missing' do
      gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_signature: valid_signature }
      )
      expect(session.failed?).to be true
    end

    it 'completes the session when signature is valid' do
      allow(session).to receive(:settle_payment!).with(captured: true).and_return(true)

      gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_payment_id: payment_id, razorpay_signature: valid_signature }
      )

      expect(session.completed?).to be true
      expect(session.external_data['razorpay_payment_id']).to eq(payment_id)
    end

    it 'is idempotent and returns immediately if session already completed' do
      session.status = 'completed'
      expect(session).not_to receive(:settle_payment!)

      res = gateway.complete_payment_session(
        payment_session: session,
        params: { razorpay_payment_id: payment_id, razorpay_signature: valid_signature }
      )
      expect(res).to eq(session)
      expect(res.completed?).to be true
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
end
