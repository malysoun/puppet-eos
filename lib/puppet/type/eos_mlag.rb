#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  Neither the name of Arista Networks nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
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
# encoding: utf-8

Puppet::Type.newtype(:eos_mlag) do
  @doc = 'Configure MLAG settings'

  ensurable

  # Parameters

  newparam(:name) do
    desc 'The resource name for the MLAG instance'
  end

  # Properties (state management)

  newproperty(:domain_id) do
    desc 'Specifies the MLAG domain ID'

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:local_interface) do
    desc 'Specifies the VLAN of the SVI upon which the switch sends '\
         'MLAG control traffic.'

    validate do |value|
      unless value.between?(1, 4094)
        fail "value #{value.inspect} is not between 1 and 4094"
      end
    end

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end
  end

  newproperty(:peer_address) do
    desc 'Specifies destination address on peer switch for MLAG control '\
         'traffic.'

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:peer_link) do
    desc 'Specifies switch interface used to communicate MLAG '\
         'control traffic.'

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:interfaces) do
    desc 'Hash of Ethernet or Port-channel interfaces to be '\
         'configured as peer links.'

    # interfaces => hash {interface: mlag_id}

    validate do |value|
      if value.is_a? Hash then super(value)
      else fail "value #{value.inspect} is invalid, must be a Hash."
      end
    end

  end

  newproperty(:enable) do
    desc 'Enables or disables the MLAG.'
    newvalues(:true, :false)
  end

end