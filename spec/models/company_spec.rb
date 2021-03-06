require 'rails_helper'

RSpec.describe Company, type: :model do
  describe '#destroy' do
    it 'destroys orphaned child statements when the company is deleted' do
      company = Company.create!(name: 'company-name')
      statement = company.statements.create!(url: 'http://example.com')

      company.destroy

      expect { statement.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#statements' do
    it 'orders statements by the last year covered' do
      company = Company.create!(name: 'company-name')
      earliest_statement = company.statements.create!(
        last_year_covered: 2014,
        url: 'http://example.com'
      )
      latest_statement = company.statements.create!(
        last_year_covered: 2017,
        url: 'http://example.com'
      )

      expect(company.statements).to eq([latest_statement, earliest_statement])
    end

    it 'handles null when ordering statements by the last year covered' do
      company = Company.create!(name: 'company-name')
      statement_without_last_year_covered = company.statements.create!(
        last_year_covered: nil,
        url: 'http://example.com'
      )
      latest_statement = company.statements.create!(
        last_year_covered: 2017,
        url: 'http://example.com'
      )

      expect(company.statements).to eq([latest_statement, statement_without_last_year_covered])
    end

    it 'orders statements by the date seen if last year covered is the same' do
      company = Company.create!(name: 'company-name')
      earliest_statement = company.statements.create!(
        last_year_covered: 2017,
        date_seen: 2.days.ago,
        url: 'http://example.com'
      )
      latest_statement = company.statements.create!(
        last_year_covered: 2017,
        date_seen: 1.day.ago,
        url: 'http://example.com'
      )

      expect(company.statements).to eq([latest_statement, earliest_statement])
    end
  end

  describe '#latest_statement' do
    it 'uses last_year_covered to determine the latest statement' do
      company = Company.create!(name: 'company-name')
      company.statements.create!(last_year_covered: 2018, url: 'http://older-statement')
      newer_statement = company.statements.create!(last_year_covered: 2019, url: 'http://newer-statement')

      expect(company.latest_statement).to eq(newer_statement)
    end

    it 'handles nil values in last_year_covered when determining the latest statement' do
      company = Company.create!(name: 'company-name')
      company.statements.create!(last_year_covered: nil, url: 'http://older-statement')
      newer_statement = company.statements.create!(last_year_covered: 2019, url: 'http://newer-statement')

      expect(company.latest_statement).to eq(newer_statement)
    end

    it 'uses date_seen to determine the latest statement when last_year_covered is identical' do
      company = Company.create!(name: 'company-name')
      company.statements.create!(date_seen: Date.parse('2019-01-01'),
                                 last_year_covered: 2019,
                                 url: 'http://seen-less-recently')
      newer_statement = company.statements.create!(date_seen: Date.parse('2019-02-01'),
                                                   last_year_covered: 2019,
                                                   url: 'http://seen-more-recently')

      expect(company.latest_statement).to eq(newer_statement)
    end

    it 'includes statements produced by other companies when returning the latest statement' do
      company1 = Company.create!(name: 'company-1')
      company2 = Company.create!(name: 'company-2')
      _company1_statement = company1.statements.create!(url: 'http://example.com/c1', last_year_covered: 2018)
      company2_statement = company2.statements.create!(url: 'http://example.com/c2', last_year_covered: 2019)
      company2_statement.additional_companies_covered << company1

      expect(company1.latest_statement).to eq(company2_statement)
    end
  end

  describe '#latest_published_statements' do
    it 'uses last_year_covered to determine the latest published statement' do
      company = Company.create!(name: 'company-name')
      _newest_but_unpublished_statement = company.statements.create!(published: false,
                                                                     last_year_covered: 2019,
                                                                     url: 'http://example.com')
      _older_published_statement = company.statements.create!(published: true,
                                                              last_year_covered: 2017,
                                                              url: 'http://example.com')
      newer_published_statement = company.statements.create!(published: true,
                                                             last_year_covered: 2018,
                                                             url: 'http://example.com')

      expect(company.latest_published_statement).to eq(newer_published_statement)
    end

    it 'handles nil values in last_year_covered when determining the latest statement' do
      company = Company.create!(name: 'company-name')
      _published_statement_for_unknown_period = company.statements.create!(published: true,
                                                                           last_year_covered: nil,
                                                                           url: 'http://example.com')
      published_statement = company.statements.create!(published: true,
                                                       last_year_covered: 2018,
                                                       url: 'http://example.com')

      expect(company.latest_published_statement).to eq(published_statement)
    end

    it 'uses date_seen to determine the latest published statement when last_year_covered is identical' do
      last_year_covered = 2018
      company = Company.create!(name: 'company-name')
      _most_recently_seen_but_unpublished_state = company.statements.create!(published: false,
                                                                             date_seen: Date.parse('2019-02-01'),
                                                                             last_year_covered: last_year_covered,
                                                                             url: 'http://example.com')
      _less_recently_seen_published_statement = company.statements.create!(published: true,
                                                                           date_seen: Date.parse('2019-01-01'),
                                                                           last_year_covered: last_year_covered,
                                                                           url: 'http://example.com')
      more_recently_seen_published_statement = company.statements.create!(published: true,
                                                                          date_seen: Date.parse('2019-01-02'),
                                                                          last_year_covered: last_year_covered,
                                                                          url: 'http://example.com')

      expect(company.latest_published_statement).to eq(more_recently_seen_published_statement)
    end

    it 'includes statements produced by other companies when returning the latest statement' do
      company1 = Company.create!(name: 'company-1')
      company2 = Company.create!(name: 'company-2')

      _company1_statement = company1.statements.create!(published: true,
                                                        last_year_covered: 2018,
                                                        url: 'http://example.com')
      company2_statement = company2.statements.create!(published: true,
                                                       last_year_covered: 2019,
                                                       url: 'http://example.com')
      company2_statement.additional_companies_covered << company1

      expect(company1.latest_published_statement).to eq(company2_statement)
    end
  end

  describe '#published_statements' do
    it 'includes statements produced by other companies' do
      company1 = Company.create!(name: 'company-1')
      company2 = Company.create!(name: 'company-2')

      company1_statement = company1.statements.create!(published: true,
                                                       url: 'http://example.com')
      company2_statement = company2.statements.create!(published: true,
                                                       url: 'http://example.com')
      company2_statement.additional_companies_covered << company1

      expect(company1.published_statements).to contain_exactly(company1_statement, company2_statement)
    end
  end

  describe '#latest_statement_for_compliance_stats' do
    let(:company) { Company.create!(name: 'company-name') }
    let(:legislation) do
      Legislation.create!(name: 'legislation-name', include_in_compliance_stats: true, icon: 'icon')
    end

    it 'does not include non-published statements' do
      company.statements.create!(url: 'http://example.com',
                                 published: false,
                                 legislations: [legislation])

      expect(company.reload.latest_statement_for_compliance_stats).to be_nil
    end

    it 'does not include published statements in excluded legislation' do
      excluded_legislation = Legislation.create!(name: 'legislation-name',
                                                 include_in_compliance_stats: false,
                                                 icon: 'icon')
      company.statements.create!(url: 'http://example.com',
                                 published: false,
                                 legislations: [excluded_legislation])

      expect(company.reload.latest_statement_for_compliance_stats).to be_nil
    end

    it 'should cache the statement as the latest statement for the company' do
      statement = company.statements.create!(url: 'http://example.com',
                                             published: true,
                                             legislations: [legislation])

      expect(company.reload.latest_statement_for_compliance_stats).to eq(statement)
    end

    it "should cache the company's latest statement based on last_year_covered" do
      _older_statement = company.statements.create!(published: true,
                                                    last_year_covered: 2018,
                                                    url: 'http://example.com',
                                                    legislations: [legislation])
      newer_statement = company.statements.create!(published: true,
                                                   last_year_covered: 2019,
                                                   url: 'http://example.com',
                                                   legislations: [legislation])

      expect(company.reload.latest_statement_for_compliance_stats).to eq(newer_statement)
    end

    it "should cache the company's latest published statement based on last_year_covered and ignore null values" do
      statement = company.statements.create!(published: true,
                                             last_year_covered: 2018,
                                             url: 'http://example.com',
                                             legislations: [legislation])
      _other_statement = company.statements.create!(published: true,
                                                    last_year_covered: nil,
                                                    url: 'http://example.com',
                                                    legislations: [legislation])

      expect(company.reload.latest_statement_for_compliance_stats).to eq(statement)
    end

    it "should cache the company's latest published statement based on date_seen after first ordering by last_year_covered" do
      _older_statement = company.statements.create!(published: true,
                                                    last_year_covered: 2019,
                                                    date_seen: Date.parse('1 Jan 2019'),
                                                    url: 'http://example.com',
                                                    legislations: [legislation])
      newer_statement = company.statements.create!(published: true,
                                                   last_year_covered: 2019,
                                                   date_seen: Date.parse('1 Feb 2019'),
                                                   url: 'http://example.com',
                                                   legislations: [legislation])

      expect(company.reload.latest_statement_for_compliance_stats).to eq(newer_statement)
    end

    it 'should update the cache if the latest published statement is deleted' do
      older_statement = company.statements.create!(published: true,
                                                   last_year_covered: 2018,
                                                   url: 'http://example.com',
                                                   legislations: [legislation])
      newer_statement = company.statements.create!(published: true,
                                                   last_year_covered: 2019,
                                                   url: 'http://example.com',
                                                   legislations: [legislation])
      newer_statement.destroy

      expect(company.reload.latest_statement_for_compliance_stats).to eq(older_statement)
    end

    it 'updates cache when a statement is associated with this company' do
      other_company = Company.create!(name: 'other-company')
      statement_from_other_company = other_company.statements.create!(published: true,
                                                                      url: 'http://example.com',
                                                                      legislations: [legislation])
      statement_from_other_company.additional_companies_covered << company

      expect(company.reload.latest_statement_for_compliance_stats).to eq(statement_from_other_company)
    end

    it 'updates cache when a statement is unassociated with this company' do
      other_company = Company.create!(name: 'other-company')
      statement_from_other_company = other_company.statements.create!(published: true,
                                                                      url: 'http://example.com',
                                                                      legislations: [legislation])
      statement_from_other_company.additional_companies_covered << company
      statement_from_other_company.additional_companies_covered.destroy(company)

      expect(company.reload.latest_statement_for_compliance_stats).to be_nil
    end
  end

  describe '#all_statements' do
    it 'orders statements by the last year covered' do
      company = Company.create!(name: 'company-name')
      earliest_statement = company.statements.create!(
        last_year_covered: 2014,
        url: 'http://example.com'
      )
      latest_statement = company.statements.create!(
        last_year_covered: 2017,
        url: 'http://example.com'
      )

      expect(company.all_statements).to eq([latest_statement, earliest_statement])
    end

    it 'handles null when ordering statements by the last year covered' do
      company = Company.create!(name: 'company-name')
      statement_without_last_year_covered = company.statements.create!(
        last_year_covered: nil,
        url: 'http://example.com'
      )
      latest_statement = company.statements.create!(
        last_year_covered: 2017,
        url: 'http://example.com'
      )

      expect(company.all_statements).to eq([latest_statement, statement_without_last_year_covered])
    end

    it 'orders statements by the date seen if last year covered is the same' do
      company = Company.create!(name: 'company-name')
      earliest_statement = company.statements.create!(
        last_year_covered: 2017,
        date_seen: 2.days.ago,
        url: 'http://example.com'
      )
      latest_statement = company.statements.create!(
        last_year_covered: 2017,
        date_seen: 1.day.ago,
        url: 'http://example.com'
      )

      expect(company.all_statements).to eq([latest_statement, earliest_statement])
    end

    it 'returns all statements associated with this company' do
      company1 = Company.create!(name: 'company-1')
      company2 = Company.create!(name: 'company-2')
      company1_statement = company1.statements.create!(url: 'http://example.com/c1')
      company2_statement = company2.statements.create!(url: 'http://example.com/c2')
      company2_statement.additional_companies_covered << company1

      expect(company1.all_statements).to contain_exactly(company1_statement, company2_statement)
    end

    it 'avoids duplicating statements when associated with multiple other companies' do
      company1 = Company.create!(name: 'company-1')
      company2 = Company.create!(name: 'company-2')
      company3 = Company.create!(name: 'company-3')
      company1_statement = company1.statements.create!(url: 'http://example.com/c1')
      company1_statement.additional_companies_covered << company2
      company1_statement.additional_companies_covered << company3

      expect(company1.all_statements).to contain_exactly(company1_statement)
    end
  end

  describe '.with_associated_published_statements_in_legislation' do
    let(:legislation) { Legislation.create!(name: 'legislation', icon: 'icon') }
    let(:company1) { Company.create!(name: 'company-1') }
    let(:company2) { Company.create!(name: 'company-2') }
    let(:statement) do
      company2.statements.create!(url: 'http://example.com',
                                  legislations: [legislation],
                                  published: true)
    end

    before do
      statement.additional_companies_covered << company1
    end

    it 'includes companies with associated statements under the legislation' do
      companies = Company.with_associated_published_statements_in_legislation(legislation.name)
      expect(companies).to contain_exactly(company1)
    end

    it 'excludes non-published statements' do
      statement.update(published: false)

      companies = Company.with_associated_published_statements_in_legislation(legislation.name)
      expect(companies).to be_empty
    end

    it 'excludes statements outside the legislation' do
      other_legislation = Legislation.create!(name: 'other-legislation', icon: 'icon')
      statement.update(legislations: [other_legislation])

      companies = Company.with_associated_published_statements_in_legislation(legislation.name)
      expect(companies).to be_empty
    end

    it 'does not duplicate companies' do
      another_statement = company2.statements.create!(url: 'http://example.com',
                                                      legislations: [legislation],
                                                      published: true)
      another_statement.additional_companies_covered << company1

      companies = Company.with_associated_published_statements_in_legislation(legislation.name)
      expect(companies).to contain_exactly(company1)
    end
  end
end
