module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-exec'

  grunt.initConfig
    coffee:
      lib:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'lib'
        ext: '.js'

    exec:
      pow_restart:
        cmd: 'touch tmp/restart.txt'

    watch:
      app:
        options:
          livereload: true
        files: ['src/**/*.coffee']
        tasks: ['coffee', 'exec:pow_restart']
      view:
        options:
          livereload: true
        files: ['views/**/*.jade']

  grunt.registerTask 'default', ['coffee', 'exec:pow_restart', 'watch']
