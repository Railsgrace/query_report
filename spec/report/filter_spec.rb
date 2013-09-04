require 'spec_helper'
require 'query_report/filter'

describe QueryReport::FilterModule do
  class DummyClass
    include QueryReport::FilterModule
  end

  let(:object) { DummyClass.new }

  describe 'supported list' do
    subject { QueryReport::FilterModule::Filter }
    its(:supported_types) { should =~ [:date, :boolean, :text] }
  end

  describe 'supported types' do
    context 'with text type' do
      subject do
        object.filter(:created_at, type: :text)
        object.filters.first
      end

      its(:column) { should be :created_at }
      its(:type) { should be :text }
      its(:custom?) { should be false }
      its(:params_key) { should be :q }

      it 'has proper comparators' do
        comps = subject.comparators
        comps.collect(&:type).should =~ [:cont]
        comps.collect(&:name).should =~ [I18n.t('query_report.filters.created_at.contains')]
        comps.collect(&:search_key).should =~ [:created_at_cont]
        comps.collect(&:search_tag_name).should =~ ['q[created_at_cont]']
      end
    end

    context 'with date type' do
      subject do
        object.filter(:created_at, type: :date)
        object.filters.first
      end

      its(:column) { should be :created_at }
      its(:type) { should be :date }
      its(:custom?) { should be false }
      its(:params_key) { should be :q }

      it 'has proper comparators' do
        comps = subject.comparators
        comps.collect(&:type).should =~ [:gteq, :lteq]
        comps.collect(&:name).should =~ [I18n.t('query_report.filters.from'), I18n.t('query_report.filters.to')]
        comps.collect(&:search_key).should =~ [:created_at_gteq, :created_at_lteq]
        comps.collect(&:search_tag_name).should =~ ['q[created_at_gteq]', 'q[created_at_lteq]']
      end
    end

    context 'with type default' do
      subject do
        object.filter(:user_id, type: :user)
        object.filters.first
      end

      its(:column) { should be :user_id }
      its(:type) { should be :user }
      its(:custom?) { should be false }
      its(:params_key) { should be :q }

      it 'has proper comparators' do
        comps = subject.comparators
        comps.collect(&:type).should =~ [:eq]
        comps.collect(&:name).should =~ [I18n.t('query_report.filters.user_id.equals')]
        comps.collect(&:search_key).should =~ [:user_id_eq]
        comps.collect(&:search_tag_name).should =~ ['q[user_id_eq]']
      end
    end
  end

  context 'with custom filter' do
    subject do
      object.filter(:user_id, type: :user_auto_complete, comp: {eq: 'Filter user'}) do |query, user_id|
        query.where(user_id: user_id)
      end
      object.filters.first
    end

    its(:column) { should be :user_id }
    its(:type) { should be :user_auto_complete }
    its(:custom?) { should be true }
    its(:params_key) { should be :custom_search }

    it 'has given comparator' do
      comps = subject.comparators
      comps.collect(&:type).should =~ [:eq]
      comps.collect(&:name).should =~ ['Filter user']
      comps.collect(&:search_key).should =~ [:user_id_eq]
      comps.collect(&:search_tag_name).should =~ ['custom_search[user_id_eq]']
    end
  end

  describe 'default values' do
    context 'with date type' do
      subject do
        object.filter(:created_at, type: :date, default: [1.weeks.ago, Time.zone.now])
        object.filters.first
      end

      its(:column) { should be :created_at }
      its(:type)   { should be :date }

      it 'has proper comparator' do
        comps = subject.comparators
        comps.collect(&:type).should =~ [:lteq, :gteq]
        comps.first.has_default?.should be true
      end
    end

    context 'with boolean type' do
      subject do
        object.filter(:created_at, type: :date, default: [1.weeks.ago, Time.zone.now])
        object.filter(:paid, type: :boolean, default: false)
        object.filters.last
      end

      its(:column) { should be :paid }
      its(:type)   { should be :boolean }

      it 'has proper comparator' do
        comps = subject.comparators
        comps.collect(&:type).should =~ [:eq]
        comps.first.has_default?.should be true
        comps.first.default.should == false
      end
    end
  end

  describe '#has_filter?' do
    context 'with filters' do
      subject do
        object.filter(:created_at, type: :date)
        object
      end

      its(:has_filter?) { should be true }
    end

    context 'with out filters' do
      subject { object }
      its(:has_filter?) { should be false }
    end
  end
end