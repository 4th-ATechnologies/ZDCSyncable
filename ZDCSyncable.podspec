Pod::Spec.new do |s|
	s.name         = "ZDCSyncable"
	s.version      = "2.2.4"
	s.summary      = "Undo, redo & merge capabilities for structs & classes in pure Swift."
	s.homepage     = "https://github.com/4th-ATechnologies/ZDCSyncable"
	s.license      = 'MIT'

	s.author = {
		"Robbie Hanson" => "robbiehanson@deusty.com"
	}
	s.source = {
		:git => "https://github.com/4th-ATechnologies/ZDCSyncable.git",
		:tag => s.version.to_s
	}

	s.osx.deployment_target = '10.10'
	s.ios.deployment_target = '10.0'
	s.tvos.deployment_target = '10.0'

	s.swift_version = '5.1'
	s.source_files = 'ZDCSyncable/*.{swift}', 'ZDCSyncable/{AnyCodable,Protocols,Utilities,Internal}/*.{swift,h,m}'

end
