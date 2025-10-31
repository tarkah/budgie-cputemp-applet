# CPU Temp Applet build

project('budgie-cputemp-applet',
	['vala', 'c'],
	version: '1.0.0',
	meson_version: '>= 0.40.0'
)

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

am_cflags = [
    '-fstack-protector',
    '-pedantic',
    '-Wstrict-prototypes',
    '-Wundef',
    '-Werror-implicit-function-declaration',
    '-Wformat',
    '-Wformat-security',
    '-Werror=format-security',
    '-Wconversion',
    '-Wunused-variable',
    '-Wunreachable-code',
    '-Wall',
    '-W',
]

add_global_arguments(am_cflags, language: 'c')
meson.add_install_script('meson_post_install.py')

# Global path variable
prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))
datadir = join_paths(prefix, get_option('datadir'))

# Global configuration data - matches vapi/config.vapi strings
conf = configuration_data()

package_version = meson.project_version()
conf.set('PACKAGE_NAME', 'budgie-cputemp-applet')
conf.set_quoted('PACKAGE_VERSION', package_version)
conf.set_quoted('PACKAGE_LIBDIR', libdir)
conf.set_quoted('PACKAGE_SHAREDIR', datadir)

config_h = configure_file(
	output: 'config.h',
	configuration: conf
)

subdir('assets')
subdir('plugin')
