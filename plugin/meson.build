LIB_INSTALL_DIR = join_paths(prefix, libdir, 'budgie-desktop', 'plugins', 'cpu-temp')

install_data(
    'CpuTempApplet.plugin',
    install_dir : LIB_INSTALL_DIR
)

gresource = join_paths(meson.current_source_dir(), 'plugin.gresource.xml')

gnome = import('gnome')

cputemp_applet_resources = gnome.compile_resources(
    'cputemp-applet-resources',
    gresource,
    source_dir: meson.current_source_dir(),
    c_name: 'budgie_cputemp',
)

applet_cputemp_sources = [
    'Sensors.vala',
    'CpuTempApplet.vala',
    cputemp_applet_resources
]

applet_cputemp_deps = [
    dependency('gtk+-3.0', version: '>= 3.24.0'),
    dependency('libpeas-1.0', version: '>= 1.26.0'),
    dependency('budgie-1.0', version: '>=2')
]

shared_library(
    'cputempapplet',
    applet_cputemp_sources,
    dependencies: applet_cputemp_deps,
    vala_args: [
        '--pkg', 'libpeas-1.0',
        '--pkg', 'gtk+-3.0',
        # Make gresource work
        '--target-glib=2.38',
        '--gresources=' + gresource,        
    ],
    install: true,
    install_dir: LIB_INSTALL_DIR,
)

install_data(
    'com.github.tarkah.budgie-cputemp-applet.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

PIXMAPS_DIR = join_paths(datadir, 'pixmaps')

install_data(
    'chip-cpu-symbolic.svg',
    install_dir: PIXMAPS_DIR
)
