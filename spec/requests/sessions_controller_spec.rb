require 'rails_helper'

RSpec.describe SessionsController do
  describe 'POST /switch' do
    subject(:send_request) { post switch_session_path, params: { user_id: } }

    let(:user_id) { user.id }
    let(:user) { create(:user) }

    before { create(:user) }

    it 'redirects to :root_path' do
      send_request
      expect(response).to redirect_to(root_path)
    end

    it 'saves provided id to session' do
      send_request
      expect(session[:current_user_id]).to eq(user.id)
    end

    context 'when user not found' do
      let(:user_id) { 0 }

      it 'responds with :not_found' do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
