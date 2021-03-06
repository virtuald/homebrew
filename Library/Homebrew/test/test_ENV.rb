require "testing_env"
require "extend/ENV"

module SharedEnvTests
  def setup
    @env = {}.extend(EnvActivation)
  end

  def test_switching_compilers
    @env.llvm
    @env.clang
    assert_nil @env["LD"]
    assert_equal @env["OBJC"], @env["CC"]
  end

  def test_with_build_environment_restores_env
    before = @env.dup
    @env.with_build_environment do
      @env["foo"] = "bar"
    end
    assert_nil @env["foo"]
    assert_equal before, @env
  end

  def test_with_build_environment_ensures_env_restored
    before = @env.dup
    begin
      @env.with_build_environment do
        @env["foo"] = "bar"
        raise Exception
      end
    rescue Exception
    end
    assert_nil @env["foo"]
    assert_equal before, @env
  end

  def test_with_build_environment_returns_block_value
    assert_equal 1, @env.with_build_environment { 1 }
  end

  def test_with_build_environment_does_not_mutate_interface
    expected = @env.methods
    @env.with_build_environment { assert_equal expected, @env.methods }
    assert_equal expected, @env.methods
  end

  def test_append_existing_key
    @env["foo"] = "bar"
    @env.append "foo", "1"
    assert_equal "bar 1", @env["foo"]
  end

  def test_append_existing_key_empty
    @env["foo"] = ""
    @env.append "foo", "1"
    assert_equal "1", @env["foo"]
  end

  def test_append_missing_key
    @env.append "foo", "1"
    assert_equal "1", @env["foo"]
  end

  def test_prepend_existing_key
    @env["foo"] = "bar"
    @env.prepend "foo", "1"
    assert_equal "1 bar", @env["foo"]
  end

  def test_prepend_existing_key_empty
    @env["foo"] = ""
    @env.prepend "foo", "1"
    assert_equal "1", @env["foo"]
  end

  def test_prepend_missing_key
    @env.prepend "foo", "1"
    assert_equal "1", @env["foo"]
  end

  # NOTE: this may be a wrong behavior; we should probably reject objects that
  # do not respond to #to_str. For now this documents existing behavior.
  def test_append_coerces_value_to_string
    @env.append "foo", 42
    assert_equal "42", @env["foo"]
  end

  def test_prepend_coerces_value_to_string
    @env.prepend "foo", 42
    assert_equal "42", @env["foo"]
  end

  def test_append_path
    @env.append_path "FOO", "/usr/bin"
    assert_equal "/usr/bin", @env["FOO"]
    @env.append_path "FOO", "/bin"
    assert_equal "/usr/bin#{File::PATH_SEPARATOR}/bin", @env["FOO"]
  end

  def test_prepend_path
    @env.prepend_path "FOO", "/usr/bin"
    assert_equal "/usr/bin", @env["FOO"]
    @env.prepend_path "FOO", "/bin"
    assert_equal "/bin#{File::PATH_SEPARATOR}/usr/bin", @env["FOO"]
  end

  def test_switching_compilers_updates_compiler
    [:clang, :llvm, :gcc, :gcc_4_0].each do |compiler|
      @env.send(compiler)
      assert_equal compiler, @env.compiler
    end
  end

  def test_deparallelize_block_form_restores_makeflags
    @env["MAKEFLAGS"] = "-j4"
    @env.deparallelize do
      assert_nil @env["MAKEFLAGS"]
    end
    assert_equal "-j4", @env["MAKEFLAGS"]
  end
end

class StdenvTests < Homebrew::TestCase
  include SharedEnvTests

  def setup
    super
    @env.extend(Stdenv)
  end
end

class SuperenvTests < Homebrew::TestCase
  include SharedEnvTests

  def setup
    super
    @env.extend(Superenv)
  end

  def test_initializes_deps
    assert_equal [], @env.deps
    assert_equal [], @env.keg_only_deps
  end
end
