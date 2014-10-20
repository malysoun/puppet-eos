#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
require 'puppet/type'
require 'puppet_x/eos/provider'

Puppet::Type.type(:eos_vlan).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    result = eapi.Vlan.get(nil)
    Puppet.debug("RESULT #{result}")

    resp = eapi.enable('show vlan trunk group')
    trunks = resp.first['trunkGroups']

    result.map do |name, attr_hash|
      provider_hash = { name: name, vlanid: name, ensure: :present }
      provider_hash[:vlan_name] = attr_hash['name']
      enable = attr_hash['status'] == 'active' ? :true : :false
      provider_hash[:enable] = enable
      provider_hash[:trunk_groups] = trunks[name]['names']
      new(provider_hash)
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def enable=(val)
    @property_flush[:enable] = val
  end

  def vlan_name=(val)
    @property_flush[:vlan_name] = val
  end

  def trunk_groups=(val)
    @property_flush[:trunk_groups] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    eapi.Vlan.add(resource[:name])
    @property_hash = { vlanid: resource[:name], ensure: :present }
    self.enable = resource[:enable] if resource[:enable]
    self.vlan_name = resource[:vlan_name] if resource[:vlan_name]
    self.trunk_groups = resource[:trunk_groups] if resource[:trunk_groups]
  end

  def destroy
    eapi.Vlan.delete(resource[:vlanid])
    @property_hash = { vlanid: resource[:vlanid], ensure: :absent }
  end

  def flush
    flush_enable_state
    flush_vlan_name
    flush_trunk_groups
    @property_hash = resource.to_hash
  end

  def flush_vlan_name
    value = @property_flush[:vlan_name]
    return nil unless value
    vlanid = resource[:vlanid]
    eapi.Vlan.set_name(id: vlanid, value: value)
  end

  def flush_trunk_groups
    proposed = @property_flush[:trunk_groups]
    return nil unless proposed
    current = @property_hash[:trunk_groups]
    current = [] if current.nil?
    id = resource[:vlanid]

    (current - proposed).each do |grp|
      eapi.Vlan.set_trunk_group(id: id, value: grp)
    end

    (proposed - current).each do |grp|
      eapi.Vlan.set_trunk_group(id: id, value: grp)
    end
  end

  def flush_enable_state
    value = @property_flush[:enable]
    return nil unless value
    arg = value ? 'suspend' : 'active'
    eapi.Vlan.set_state(resource[:vlanid], arg)
  end
end
