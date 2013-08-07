require 'spec_helper'
require 'query_report/filter'

describe QueryReport::FilterModule do
  class DummyClass
    include QueryReport::FilterModule
  end

  before(:each) do
    @object = DummyClass.new
  end

  it 'should have date and text in the supported list' do
    QueryReport::FilterModule::Filter.supported_types.should =~ [:date, :boolean, :text]
  end

  describe 'supported types' do
    it 'filters with type text' do
      @object.filter(:created_at, type: :text)
      @object.filters.size.should be 1
      filter = @object.filters.first

      filter.column.should be :created_at
      filter.type.should be :text
      filter.custom?.should be false
    end

    it 'filters with type date' do
      @object.filter(:created_at, type: :date)
      filter = @object.filters.first

      filter.column.should be :created_at
      filter.type.should be :date
      filter.custom?.should be false
    end

    it 'filters with default type' do
      @object.filter(:user_id, type: :user)
      filter = @object.filters.first

      filter.column.should be :user_id
      filter.type.should be :user
      filter.comparators.collect(&:type).should =~ [:eq]
      filter.comparators.collect(&:name).should =~ [I18n.t('query_report.filters.user_id.equals')]
      filter.custom?.should be false
    end
  end

  context 'custom filter' do
    it 'filters with given block' do
      @object.filter(:user_id, type: :user_auto_complete, comp: {eq: 'Filter user'}) do |query, user_id|
        query.where(user_id: user_id)
      end
      filter = @object.filters.first

      filter.column.should be :user_id
      filter.type.should be :user_auto_complete
      filter.comparators.collect(&:type).should =~ [:eq]
      filter.comparators.collect(&:name).should =~ ['Filter user']
      filter.custom?.should be true
    end
  end

  describe 'detect comparators' do
    it 'detects for text type' do
      @object.filter(:created_at, type: :text)

      filter = @object.filters.first
      filter.comparators.collect(&:type).should =~ [:cont]
      filter.comparators.collect(&:name).should =~ [I18n.t('query_report.filters.created_at.contains')]
    end

    it 'detects for date type' do
      @object.filter(:created_at, type: :date)

      filter = @object.filters.first
      filter.comparators.collect(&:type).should =~ [:gteq, :lteq]
      filter.comparators.collect(&:name).should =~ [I18n.t('query_report.filters.from'), I18n.t('query_report.filters.to')]
    end

    it 'sets default comparator' do
      @object.filter :created_at

      filter = @object.filters.first
      filter.comparators.collect(&:type).should =~ [:eq]
      filter.comparators.collect(&:name).should =~ [I18n.t("query_report.filters.created_at.equals")]
    end
  end

  it 'supports initial filter value' do
    from = 1.weeks.ago
    to = Time.now
    @object.filter(:created_at, type: :date, default: [from, to])
    filter = @object.filters.first

    expect(filter.column).to be :created_at
    expect(filter.type).to be :date

    from_comp = filter.comparators.first
    expect(from_comp.type).to be :gteq
    expect(from_comp.has_default?).to be true
  end
end