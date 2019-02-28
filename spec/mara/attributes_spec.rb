require 'spec_helper'

RSpec.describe  Mara::Model::Attributes do
  let(:instance) {  Mara::Model::Attributes.new({}) }

  before do
    instance.set(:first_name, 'Maddie')
    instance.set(:last_name, 'Schipper')
  end

  subject { instance }

  describe '#key?' do
    it { expect(subject.key?(:first_name)).to be true }
    it { expect(subject.key?('first_name')).to be true }
    it { expect(subject.key?('FirstName')).to be true }

    it { expect(subject.key?(:foo_bar)).to be false }
    it { expect(subject.key?('foo_bar')).to be false }
    it { expect(subject.key?('FooBar')).to be false }
  end

  describe '#set' do
    context 'given a nil value' do
      it 'removes the key' do
        expect(subject.key?(:last_name)).to be true
        subject.set(:last_name, nil)
        expect(subject.key?(:last_name)).to be false
      end
    end
  end

  describe '#get' do
    it { expect(subject.get(:first_name)).to eq 'Maddie' }
    it { expect(subject.get('first_name')).to eq 'Maddie' }
    it { expect(subject.get('FirstName')).to eq 'Maddie' }
  end

  describe '#fetch' do
    it { expect(subject.fetch(:first_name, 'Testing')).to eq 'Maddie' }

    it { expect(subject.fetch(:foo_bar, 'Testing')).to eq 'Testing' }
  end

  describe '#to_h' do
    it 'dumps the storage' do
      expect(subject.to_h).to eq(
        'FirstName' => 'Maddie',
        'LastName' => 'Schipper'
      )
    end
  end

  describe 'dynamic methods' do
    it 'uses set' do
      expect(subject).to receive(:set).with('foo', 'bar')
      subject.foo = 'bar'
    end

    it 'uses get' do
      expect(subject).to receive(:get).with(:foo)
      subject.foo
    end

    it 'responds to dynamic' do
      expect(subject).to respond_to(:foo)
    end
  end
end
