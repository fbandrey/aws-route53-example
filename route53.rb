require 'aws-sdk'
require 'yaml'

CONFIG = YAML.load(File.read('config.yml'))
RECORDS_LIMIT = 1_000

# Class describes the service for retrieving list of records
# for desired DNS zone.
# Example:
#   service = ShowRecordsService.new('google.com')
#   service.call('MX')
class ShowRecordsService
  def initialize(required_zone, region = 'us-west-2')
    @required_zone = required_zone
    @region = region
  end

  def call(record_type = 'A')
    target_zones.each do |zone|
      zone_records = client.list_resource_record_sets(
        hosted_zone_id: zone.id,
        max_items: RECORDS_LIMIT
      ).resource_record_sets

      print_records(zone, records_by_type(zone_records, record_type))
    end
  end

  def records_by_type(records, type)
    records.select { |record| record.type == type }
  end

  def target_zones
    all_zones.select { |zone| zone.name.match @required_zone }
  end

  def all_zones
    client.list_hosted_zones.hosted_zones
  end

  private

  def client
    @client ||= Aws::Route53::Client.new(
      credentials: credentials,
      region: @region
    )
  end

  def credentials
    @credentials ||= Aws::Credentials.new(
      CONFIG['aws']['key'],
      CONFIG['aws']['secret']
    )
  end

  def print_records(zone, records)
    puts "=== Zone '#{zone.name}' (ID: #{zone.id}) ==="
    records.each do |record|
      puts [
        record.name,
        record.type,
        record.resource_records.map(&:value).join(' '),
        record.ttl
      ].join(',')
    end
  end
end

# Run the service.
ShowRecordsService.new('syseng-interview.amplify').call
