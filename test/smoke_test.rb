require_relative "test_helper"
require "sassc"

module SmokeTest
  SAMPLE_SASS_STRING = "$size: 30px; .hi { width: $size; }"
  SAMPLE_CSS_OUTPUT = ".hi {\n  width: 30px; }\n"
  BAD_SASS_STRING = "$size = 30px;"

  class General < MiniTest::Test
    def test_it_reports_the_libsass_version
      assert_equal "3.1.0", SassC::Native.version
    end
  end

  class DataContext < MiniTest::Test
    def test_compile_status_is_zero_when_successful
      data_context = SassC::Native.make_data_context(SAMPLE_SASS_STRING)
      context = SassC::Native.data_context_get_context(data_context)

      status = SassC::Native.compile_data_context(data_context)
      assert_equal 0, status

      status = SassC::Native.context_get_error_status(context)
      assert_equal 0, status
    end

    def test_compiled_css_is_correct
      data_context = SassC::Native.make_data_context(SAMPLE_SASS_STRING)
      context = SassC::Native.data_context_get_context(data_context)
      SassC::Native.compile_data_context(data_context)

      css = SassC::Native.context_get_output_string(context)
      assert_equal SAMPLE_CSS_OUTPUT, css
    end

    def test_compile_status_is_one_if_failed
      data_context = SassC::Native.make_data_context(BAD_SASS_STRING)
      context = SassC::Native.data_context_get_context(data_context)

      status = SassC::Native.compile_data_context(data_context)
      refute_equal 0, status

      status = SassC::Native.context_get_error_status(context)
      refute_equal 0, status
    end

    def test_failed_compile_gives_error_message
    end
  end

  class FileContext < MiniTest::Test
    include TestConstruct::Helpers

    def around
      within_construct do |construct|
        @construct = construct
        yield
      end

      @construct = nil
    end

    def test_compile_status_is_zero_when_successful
      @construct.file("style.scss", SAMPLE_SASS_STRING)

      file_context = SassC::Native.make_file_context("style.scss")
      context = SassC::Native.file_context_get_context(file_context)

      status = SassC::Native.compile_file_context(file_context)
      assert_equal 0, status

      status = SassC::Native.context_get_error_status(context)
      assert_equal 0, status
    end

    def test_compiled_css_is_correct
      @construct.file("style.scss", SAMPLE_SASS_STRING)

      file_context = SassC::Native.make_file_context("style.scss")
      context = SassC::Native.file_context_get_context(file_context)
      SassC::Native.compile_file_context(file_context)

      css = SassC::Native.context_get_output_string(context)
      assert_equal SAMPLE_CSS_OUTPUT, css
    end

    def test_invalid_file_name
      @construct.file("style.scss", SAMPLE_SASS_STRING)

      file_context = SassC::Native.make_file_context("style.jajaja")
      context = SassC::Native.file_context_get_context(file_context)
      status = SassC::Native.compile_file_context(file_context)

      refute_equal 0, status

      error = SassC::Native.context_get_error_message(context)

      assert_match "Error: File to read not found or unreadable: style.jajaja",
                   error
    end

    def test_file_import
      @construct.file("not_included.scss", "$size: 30px;")
      @construct.file("import_parent.scss", "$size: 30px;")
      @construct.file("import.scss", "@import 'import_parent'; $size: 30px;")
      @construct.file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

      file_context = SassC::Native.make_file_context("styles.scss")
      context = SassC::Native.file_context_get_context(file_context)
      status = SassC::Native.compile_file_context(file_context)

      assert_equal 0, status

      css = SassC::Native.context_get_output_string(context)
      assert_equal SAMPLE_CSS_OUTPUT, css

      included_files = SassC::Native.context_get_included_files(context)
      included_files.sort!

      assert_match /import.scss/, included_files[0]
      assert_match /import_parent.scss/, included_files[1]
      assert_match /styles.scss/, included_files[2]
    end
  end
end
