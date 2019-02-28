require 'spec_helper'

RSpec.describe  Mara::AttributeFormatter do
  describe '.format' do
    it { expect(described_class.format(true)).to eq(bool: true) }
    it { expect(described_class.format(false)).to eq(bool: false) }
    it { expect(described_class.format(nil)).to eq(null: true) }
    it { expect(described_class.format(:foo)).to eq(s: 'foo') }
    it { expect(described_class.format(1.2)).to eq(n: '1.2') }
    it { expect(described_class.format(100)).to eq(n: '100') }
    it { expect(described_class.format(100)).to eq(n: '100') }
    it { expect(described_class.format(Time.at(1_544_634_052))).to eq(n: '1544634052') }
    it { expect(described_class.format(Time.at(1_544_634_052).to_datetime)).to eq(n: '1544634052') }
    it { expect(described_class.format({})).to eq(null: true) }
    it { expect(described_class.format(foo: :bar, baz: true)).to eq(m: { 'foo' => { s: 'bar' }, 'baz' => { bool: true } }) }
    it { expect(described_class.format([])).to eq(null: true) }
    it { expect(described_class.format([:foo, 1])).to eq(l: [{ s: 'foo' }, { n: '1' }]) }
    it { expect(described_class.format(Set.new([]))).to eq(null: true) }
    it { expect(described_class.format(Set.new(%i[foo bar]))).to eq(ss: %w[foo bar]) }
    it { expect(described_class.format(Set.new(%w[foo bar]))).to eq(ss: %w[foo bar]) }
    it { expect(described_class.format(Set.new([42, 13.37]))).to eq(ns: ['42', '13.37']) }

    it { expect { described_class.format(Set.new([Object.new])) }.to raise_error  Mara::AttributeFormatter::Error }
    it { expect { described_class.format(Set.new(['foo', 12])) }.to raise_error  Mara::AttributeFormatter::Error }
    it { expect { described_class.format(Object.new) }.to raise_error  Mara::AttributeFormatter::Error }
  end

  describe '.flatten' do
    context 'given an invalid type' do
      it 'raises an error' do
        expect { described_class.flatten(Object.new) }.to raise_error ArgumentError do |error|
          expect(error.message).to eq 'Not an attribute type'
        end
      end
    end

    context 'given a string' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(s: 'Testing') }

      it { expect(described_class.flatten(attr)).to eq 'Testing' }
    end

    context 'given a integer' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(n: '42') }

      it { expect(described_class.flatten(attr)).to eq 42 }
    end

    context 'given a float' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(n: '42.42') }

      it { expect(described_class.flatten(attr)).to eq 42.42 }
    end

    context 'given a string set' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(ss: %w[one two]) }

      it { expect(described_class.flatten(attr)).to eq Set.new(%w[one two]) }
    end

    context 'given a number set' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(ns: %w[42 42.42]) }

      it { expect(described_class.flatten(attr)).to eq Set.new([42, 42.42]) }
    end

    context 'given a map' do
      let(:str) { Aws::DynamoDB::Types::AttributeValue.new(s: 'Testing') }
      let(:num) { Aws::DynamoDB::Types::AttributeValue.new(n: '42.42') }
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(m: { :string => str, 'number' => num }) }

      it { expect(described_class.flatten(attr)).to eq(string: 'Testing', 'number' => 42.42) }
    end

    context 'given a list' do
      let(:str) { Aws::DynamoDB::Types::AttributeValue.new(s: 'Testing') }
      let(:num) { Aws::DynamoDB::Types::AttributeValue.new(n: '42.42') }
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(l: [str, num]) }

      it { expect(described_class.flatten(attr)).to eq(['Testing', 42.42]) }
    end

    context 'given null' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(null: true) }

      it { expect(described_class.flatten(attr)).to be_a  Mara::NullValue }
    end

    context 'given true bool' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(bool: true) }

      it { expect(described_class.flatten(attr)).to eq true }
    end

    context 'given false bool' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new(bool: false) }

      it { expect(described_class.flatten(attr)).to eq false }
    end

    context 'given nil value' do
      let(:attr) { Aws::DynamoDB::Types::AttributeValue.new }

      it { expect { described_class.flatten(attr) }.to raise_error( Mara::AttributeFormatter::Error) }
    end
  end
end
