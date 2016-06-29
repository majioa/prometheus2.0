require 'rails_helper'

describe AllBugsForMaintainer do
  describe '#initialize' do
    let(:branch) { double }

    let(:maintainer) { double }

    subject { described_class.new(branch, maintainer) }

    its(:branch) { should eq(branch) }

    its(:maintainer) { should eq(maintainer) }
  end

  describe '#query' do
    let(:branch) { double }

    let(:maintainer) { stub_model Maintainer, email: 'icesik@altlinux.org' }

    let(:components) { double }

    subject { described_class.new(branch, maintainer) }

    before { expect(subject).to receive(:components).and_return(components) }

    before do
      #
      # Bug.where('component IN (?) OR assigned_to = ?', components, maintainer.email).order(bug_id: :desc)
      #
      expect(Bug).to receive(:where).with('component IN (?) OR assigned_to = ?', components, maintainer.email) do
        double.tap do |a|
          expect(a).to receive(:order).with(bug_id: :desc)
        end
      end
    end

    specify { expect { subject.query }.not_to raise_error }
  end

  describe '#decorate' do
    let(:branch) { double }

    let(:maintainer) { double }

    subject { described_class.new(branch, maintainer) }

    before do
      #
      # subject.query.decorate
      #
      expect(subject).to receive(:query) do
        double.tap do |a|
          expect(a).to receive(:decorate)
        end
      end
    end

    specify { expect { subject.decorate }.not_to raise_error }
  end

  # private methods

  describe '#components' do
    let(:branch) { double }

    let(:maintainer) { double }

    let(:maintainer_packages_name) { double }

    subject { described_class.new(branch, maintainer) }

    before { expect(subject).to receive(:maintainer_packages_name).and_return(maintainer_packages_name) }

    before do
      #
      # branch.srpms.joins(:packages).where(name: maintainer_packages_name).pluck('packages.name').sort.uniq
      #
      expect(branch).to receive(:srpms) do
        double.tap do |a|
          expect(a).to receive(:joins).with(:packages) do
            double.tap do |b|
              expect(b).to receive(:where).with(name: maintainer_packages_name) do
                double.tap do |c|
                  expect(c).to receive(:pluck).with('packages.name') do
                    double.tap do |d|
                      expect(d).to receive(:sort) do
                        double.tap do |e|
                          expect(e).to receive(:uniq)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    specify { expect { subject.send(:components) }.not_to raise_error }
  end

  describe '#maintainer_packages_name' do
    let(:branch) { stub_model Branch, name: 'Sisyphus' }

    let(:maintainer) { stub_model Maintainer, login: 'icesik' }

    subject { described_class.new(branch, maintainer) }

    before do
      #
      # Redis.current.smembers("#{ branch.name }:maintainers:#{ maintainer.login }")
      #
      expect(Redis).to receive(:current) do
        double.tap do |a|
          expect(a).to receive(:smembers).with("#{ branch.name }:maintainers:#{ maintainer.login }")
        end
      end
    end

    specify { expect { subject.send(:maintainer_packages_name) }.not_to raise_error }
  end
end
