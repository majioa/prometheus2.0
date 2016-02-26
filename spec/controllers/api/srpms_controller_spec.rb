require 'rails_helper'

describe Api::SrpmsController do
  describe '#show' do
    before { get :show, id: 'glibc', format: :json }

    it { should render_template(:show) }

    it { should respond_with(:ok) }
  end

  # private methods

  describe '#resource' do
    let(:params) { { id: 'glibc' } }

    before { expect(subject).to receive(:params).and_return(params) }

    before do
      #
      # subject.branch.srpms.where(name: params[:id]).includes(:branch).first!
      #
      expect(subject).to receive(:branch) do
        double.tap do |a|
          expect(a).to receive(:srpms) do
            double.tap do |b|
              expect(b).to receive(:where).with(name: params[:id]) do
                double.tap do |c|
                  expect(c).to receive(:includes).with(:branch) do
                    double.tap do |d|
                      expect(d).to receive(:first!)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    specify { expect { subject.send(:resource) }.not_to raise_error }
  end
end
