Pod::Spec.new do |s|
	s.name         = "ZDCSyncable"
	s.version      = "1.0"
	s.summary      = "Undo, redo & merge capabilities for plain objects in Swift (and objective-c)."
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

	s.swift_version = '5.0'
	s.default_subspecs = 'Swift'

	s.subspec 'Swift' do |ss|

		ss.source_files = 'ZDCSyncable/Swift/*.{swift}', 'ZDCSyncable/Swift/{Internal,Utilities}/*.{swift,h,m}'
	end

	s.subspec 'ObjC' do |ss|

		ss.source_files = 'ZDCSyncable/ObjC/*.{h,m}', 'ZDCSyncable/ObjC/{Internal,Utilities}/*.{h,m}'
		ss.private_header_files = 'ZDCSyncable/ObjC/Internal/*.h'
	end

end
