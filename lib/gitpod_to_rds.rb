require 'aws-sdk-ec2'
require 'pry'

class GitpodToRds
  def self.run sg_id:, ip_protocol:, from_port:, to_port:, description:, ip_address:
    raise "ip address must not be blank" if ip_address.nil?

    cidr_ip_range = "#{ip_address}/32"
    client = GitpodToRds.ec2_client
    sg     = GitpodToRds.describe_security_group client: client, sg_id: sg_id
    matches = GitpodToRds.ingress_rule_exist?({
      sg: sg,
      ip_protocol: ip_protocol,
      from_port: from_port,
      to_port: to_port,
      cidr_ip: cidr_ip_range,
      description: description
    })

    if matches[:bad_cidr_match] != false
      puts 'deleting rule due to mismatch cidr range'
      puts "cidr_ip: #{matches[:bad_cidr_match][:cidr_ip]}"
      puts "description: #{matches[:bad_cidr_match][:description]}"
      GitpodToRds.delete_ingress_rule({
        client: client,
        sg_id: sg_id,
        ip_protocol: 'tcp', 
        from_port: from_port, 
        to_port: to_port,
        # we match on descrpition to delete the bad cdir_range
        cidr_ip_range: matches[:bad_cidr_match][:cidr_ip]
      })
    end

    if matches[:bad_description_match] != false
      puts 'deleting rule due to mismatch description:'
      puts "cidr_ip: #{matches[:bad_description_match][:cidr_ip]}"
      puts "description: #{matches[:bad_description_match][:description]}"
      GitpodToRds.delete_ingress_rule({
        client: client,
        sg_id: sg_id,
        ip_protocol: 'tcp', 
        from_port: from_port, 
        to_port: to_port,
        # we match on cidr_ip_range to delete the bad description
        cidr_ip_range: matches[:bad_description_match][:cidr_ip]
      })
    end

    if matches[:exact_match] == true
      puts 'rule already exists, do nothing'
    else 
      puts "create a new rule"
      GitpodToRds.create_ingress_rule({
        client: client,
        sg_id: sg_id,
        ip_protocol: 'tcp', 
        from_port: from_port, 
        to_port: to_port,
        cidr_ip_range: cidr_ip_range,
        description: description
      })
    end
  end

  def self.ec2_client
    client = Aws::EC2::Client.new({
    region: 'us-east-1',
    credentials: Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY']
    )})
  end

  def self.describe_security_group client:, sg_id:
    sg = client.describe_security_groups({group_ids: [sg_id]}).first.security_groups.first
    return sg
  end

  # Does a ingress rule already exist for Gitpod?
  def self.ingress_rule_exist? sg:, ip_protocol:, from_port:, to_port:, cidr_ip:, description:
    matches = {
      exact_match: false,
      bad_cidr_match: false,
      bad_description_match: false
    }
    sg.ip_permissions.each do |t|
      # found a match for a rule group:
      if (t.ip_protocol == ip_protocol &&
          t.from_port == from_port &&
          t.to_port == to_port)
        matches[:exact_match]    = true if t.ip_ranges.any?{|tt| tt.description == description  && tt.cidr_ip == cidr_ip }
        bad_cidr_match = t.ip_ranges.find{|tt| tt.description == description && tt.cidr_ip != cidr_ip }
        if bad_cidr_match
          matches[:bad_cidr_match] = {
            cidr_ip:  bad_cidr_match.cidr_ip,
            description: bad_cidr_match.description
          } 
        end
        bad_description_match =  t.ip_ranges.find{|tt| tt.description != description  && tt.cidr_ip == cidr_ip }
        if bad_description_match
          matches[:bad_description_match] = {
            cidr_ip:  bad_description_match.cidr_ip,
            description: bad_description_match.description
          }
        end
      end
    end
    return matches
  end

  # Update the rule for the
  def self.delete_ingress_rule client:, sg_id:, ip_protocol:, from_port:, to_port:, cidr_ip_range: nil, description: nil
    ip_range = {}
    ip_range[:cidr_ip] = cidr_ip_range if cidr_ip_range
    ip_range[:description]   = description   if description
    if cidr_ip_range.nil? && description.nil?
      raise "You have to provide at a  cidr_ip_range or description when revoking an ingress rule"
    end
    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/EC2/Client.html#revoke_security_group_ingress-instance_method
    client.revoke_security_group_ingress(
      group_id: sg_id,
      ip_permissions: [
        {
          ip_protocol: ip_protocol,
          from_port: from_port,
          to_port: to_port,
          ip_ranges: [ip_range]
        }
      ]
    )
  end

  def self.create_ingress_rule client:, sg_id:, ip_protocol:, from_port:, to_port:, cidr_ip_range:, description:
    puts cidr_ip_range
    # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/EC2/Client.html#authorize_security_group_ingress-instance_method
    client.authorize_security_group_ingress(
      group_id: sg_id,
      ip_permissions: [
        {
          ip_protocol: ip_protocol,
          from_port: from_port,
          to_port: to_port,
          ip_ranges: [
            {
              cidr_ip: cidr_ip_range,
              description: description
            }
          ]
        }
      ]
    )
    return true
  rescue StandardError => e
    puts "Error adding inbound rule to security group: #{e.message}"
    return false
  end # def self.create_ingress_rule
end