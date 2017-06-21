{
	'targets': [
	{
		'target_name': 'x-bridge',
			'sources': [
				"src/x-bridge.cc"
			],
			'conditions': [
				['OS=="mac"', {
					'xcode_settings': {
						'OTHER_CPLUSPLUSFLAGS': ['-std=c++11', '-stdlib=libc++'],
						'MACOSX_DEPLOYMENT_TARGET': '10.7.0',
					}
				}],
			['OS in "linux solaris"', {
				'cflags': [
					'-std=c++0x',
				'-Wno-unused-result',
				'-Wno-missing-field-initializers',
				],
				'cflags_cc!': [
					'-fno-rtti'
				]
			}],
			['OS=="win"', {
				'msvs_disabled_warnings': [
					4244,  # conversion from 'double' to 'int', possible loss of data
					4267,  # conversion from 'size_t' to 'int', possible loss of data
					4530,  # C++ exception handler used, but unwind semantics are not enabled
				],
				'msvs_settings': {
					'VCCLCompilerTool' : {
						'AdditionalOptions' : ['/EHsc']
					}
				},
				'defines': [
					'ONIG_EXTERN=extern',
				],

			}],
			['OS=="freebsd"', {
				'cflags': [
					'-std=c++0x',
				]
			}]
		]
	}
	]
}
