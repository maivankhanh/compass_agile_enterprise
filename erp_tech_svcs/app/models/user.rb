class User < ActiveRecord::Base
  include ErpTechSvcs::Utils::CompassAccessNegotiator
  include ActiveModel::Validations

  attr_accessor :password_validator

  belongs_to :party

  attr_accessible :email, :password, :password_confirmation
  authenticates_with_sorcery!
  has_capability_accessors

  #password validations
  validates_confirmation_of :password, :message => "should match confirmation", :if => :password
  validates :password, :presence => true, :password_strength => true, :if => :password

  #email validations
  validates :email, :presence => {:message => 'Email cannot be blank'}, :uniqueness => {:case_sensitive => false}
  validates_format_of :email, :with => /\b[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z/

  #username validations
  validates :username, :presence => {:message => 'Username cannot be blank'}, :uniqueness => {:case_sensitive => false}

  #these two methods allow us to assign instance level attributes that are not persisted.  These are used for mailers
  def instance_attributes
    @instance_attrs.nil? ? {} : @instance_attrs
  end

  def add_instance_attribute(k,v)
    @instance_attrs = {} if @instance_attrs.nil?
    @instance_attrs[k] = v
  end

  # roles this user does NOT have
  def roles_not
    party.roles_not
  end

  # roles this user has
  def roles
    party.security_roles
  end

  def has_role?(*passed_roles)
    result = false
    passed_roles.flatten!
    passed_roles.each do |role|
      role_iid = role.is_a?(SecurityRole) ?  role.internal_identifier : role.to_s
      all_uniq_roles.each do |this_role|
        result = true if (this_role.internal_identifier == role_iid)
        break if result
      end
      break if result
    end
    result
  end

  def add_role(role)
    party.add_role(role)
  end

  def add_roles(*passed_roles)
    party.add_roles(*passed_roles)
  end

  def remove_roles(*passed_roles)
    party.remove_roles(*passed_roles)
  end

  def remove_role(role)
    party.remove_role(role)
  end

  def remove_all_roles
    party.remove_all_roles
  end

  # user lives on FROM side of relationship
  def group_relationships
    role_type = RoleType.find_by_internal_identifier('group_member')
    PartyRelationship.where(:party_id_from => self.party.id, :role_type_id_from => role_type.id)
  end

  def join_party_relationships
    role_type = RoleType.find_by_internal_identifier('group_member')
    "party_relationships ON party_id_from = #{self.party.id} AND party_id_to = parties.id AND role_type_id_from=#{role_type.id}"
  end

  # party records for the groups this user belongs to
  def group_parties
    Party.joins("JOIN #{join_party_relationships}")
  end

  # groups this user belongs to
  def groups
    Group.joins(:party).joins("JOIN #{join_party_relationships}")
  end

  # groups this user does NOT belong to
  def groups_not
    Group.joins(:party).joins("LEFT JOIN #{join_party_relationships}").where("party_relationships.id IS NULL")
  end

  # roles assigned to the groups this user belongs to
  def group_roles
    SecurityRole.joins(:parties).
      where(:parties => {:business_party_type => 'Group'}).
      where("parties.business_party_id IN (#{groups.select('groups.id').to_sql})")
  end

  # composite roles for this user
  def all_roles
    SecurityRole.joins(:parties).joins("LEFT JOIN users ON parties.id=users.party_id").
      where("(parties.business_party_type='Group' AND 
              parties.business_party_id IN (#{groups.select('groups.id').to_sql})) OR 
             (users.id=#{self.id})")
  end

  def all_uniq_roles
    all_roles.all.uniq
  end

  def group_capabilities
    Capability.joins(:capability_type).joins(:capability_accessors).
          where(:capability_accessors => { :capability_accessor_record_type => "Group" }).
          where("capability_accessor_record_id IN (#{groups.select('groups.id').to_sql})")
  end

  def role_capabilities
    Capability.joins(:capability_type).joins(:capability_accessors).
          where(:capability_accessors => { :capability_accessor_record_type => "SecurityRole" }).
          where("capability_accessor_record_id IN (#{all_roles.select('security_roles.id').to_sql})")
  end

  def all_capabilities
    Capability.joins(:capability_type).joins(:capability_accessors).
          where("(capability_accessors.capability_accessor_record_type = 'Group' AND
                  capability_accessor_record_id IN (#{groups.select('groups.id').to_sql})) OR
                 (capability_accessors.capability_accessor_record_type = 'SecurityRole' AND
                  capability_accessor_record_id IN (#{all_roles.select('security_roles.id').to_sql})) OR
                 (capability_accessors.capability_accessor_record_type = 'User' AND
                  capability_accessor_record_id = #{self.id})")
  end

  def all_uniq_capabilities
    all_capabilities.all.uniq
  end

  def group_class_capabilities
    scope_type = ScopeType.find_by_internal_identifier('class')
    group_capabilities.where(:scope_type_id => scope_type.id)
  end

  def role_class_capabilities
    scope_type = ScopeType.find_by_internal_identifier('class')
    role_capabilities.where(:scope_type_id => scope_type.id)
  end

  def all_class_capabilities
    scope_type = ScopeType.find_by_internal_identifier('class')
    all_capabilities.where(:scope_type_id => scope_type.id)
  end

  def all_uniq_class_capabilities
    all_class_capabilities.all.uniq
  end

  def class_capabilities_to_hash
    all_uniq_class_capabilities.map {|capability| 
      { :capability_type_iid => capability.capability_type.internal_identifier, 
        :capability_resource_type => capability.capability_resource_type 
      }
    }.compact
  end

end
