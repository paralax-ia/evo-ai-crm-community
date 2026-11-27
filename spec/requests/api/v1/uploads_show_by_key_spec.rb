# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::UploadsController show_by_key', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:service_token) { 'valid-service-token' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('EVOAI_CRM_API_TOKEN').and_return(service_token)
  end

  describe 'GET /api/v1/media/:key' do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('%PDF-1.4 test stream'),
        filename: 'catalogo_teste.pdf',
        content_type: 'application/pdf',
        key: 'catalogo_teste_key.pdf'
      )
    end

    it 'returns the dynamic proxy URL and metadata when authenticated via service token' do
      get "/api/v1/media/#{blob.key}", headers: { 'X-Service-Token' => service_token }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['blob_key'] || json['data']['filename']).to eq('catalogo_teste.pdf')
      expect(json['data']['file_url']).to include('/rails/active_storage/blobs/')
      expect(json['data']['content_type']).to eq('application/pdf')
    end

    it 'returns not found when blob does not exist' do
      get '/api/v1/media/nonexistent.pdf', headers: { 'X-Service-Token' => service_token }

      expect(response).to have_http_status(:not_found)
    end
  end
end
