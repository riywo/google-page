module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.initConfig
    coffee:
      app:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'app'
        ext: '.js'

    watch:
      app:
        options:
          livereload: true
        files: ['src/**/*.coffee']
        tasks: ['coffee', 'test']

  grunt.registerTask 'default', ['coffee', 'watch']
