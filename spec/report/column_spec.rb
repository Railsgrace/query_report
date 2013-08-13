require 'spec_helper'
require 'query_report/column'
require 'fake/active_record/models'

describe QueryReport::ColumnModule do
  class DummyClass
    include QueryReport::ColumnModule
  end
  let(:object) { DummyClass.new }
  before do
    object.columns = []
    object.stub(:model_class).and_return(Readership)
  end

  context 'defined columns' do
    before { object.column :user_id }
    subject { object.columns.first }
    its(:name) { should be :user_id }
    its(:type) { should be :integer }
  end

  context 'custom columns' do
    before do
      object.column :user, type: :integer do |obj|
        link_to obj.user.name, obj.user
      end
    end
    subject { object.columns.first }
    its(:name) { should be :user }
    its(:type) { should be :integer }
    its(:data) { should_not be nil }
  end

  describe '#humanize' do
    context 'with built in readable column name' do
      before { object.column :user_id }
      subject { object.columns.first }
      its(:humanize) { should == 'User' }
    end

    context 'with custom column name' do
      before { object.column :user_id, as: 'Admin' }
      subject { object.columns.first }
      its(:humanize) { should == 'Admin' }
    end
  end

  describe '#value' do
    context 'with value from db property' do
      let(:record) { Readership.new(user_id: 1) }
      before { object.column :user_id }
      subject { object.columns.first }

      it 'fetches property value' do
        subject.value(record).should == 1
      end
    end

    context 'with value from given block' do
      let(:user)   { User.create(name: 'Jitu', age: 30) }
      let(:record) { Readership.create!(user_id: user.id) }
      before do
        object.column :user, type: :string do |obj|
          "#{obj.user.name} is @#{obj.user.age}"
        end
      end
      subject { object.columns.first }

      it 'evaluates block value' do
        subject.value(record).should == 'Jitu is @30'
      end
    end
  end
end