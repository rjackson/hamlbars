require 'spec_helper.rb'
require 'active_support'
require 'active_support/core_ext/string/output_safety'

describe Hamlbars::Template do

  let(:template_file) { Tempfile.new 'hamlbars_template' }

  before :each do
    template_file.rewind
  end

  after :each do
    template_file.flush
  end

  after :all do
    template_file.unlink
  end

  def to_handlebars(s)
    template_file.write(s)
    template_file.rewind
    handlebars = Hamlbars::Template.new(template_file, :format => :xhtml).render
    handlebars.chomp
  end

  it "should render compiler preamble" do
    to_handlebars('').should == ''
  end

  it "should bind element attributes" do
    to_handlebars('%img{ :bind => { :src => "logoUri" }, :alt => "Logo" }').should ==
      "<img {{bind-attr src=\"logoUri\"}} alt=\'Logo\' />"
  end

  it "should render action attributes" do
    to_handlebars('%a{ :_action => \'edit article on="click"\' } Edit').should ==
      '<a {{action edit article on="click"}}>Edit</a>'
  end

  it "should render in-tag expressions" do
    to_handlebars('%div{:hb => \'testExpression\'}').should ==
      '<div {{testExpression}}></div>'
  end

  it 'should render multiple in-tag expressions' do
    to_handlebars('%div{:hb => [\'firstTestExpression\', \'secondTestExpression withArgument\']}').should ==
      '<div {{firstTestExpression}} {{secondTestExpression withArgument}}></div>'
  end

  it "should render expressions" do
    to_handlebars('= hb "hello"').should ==
      "{{hello}}"
  end

  it "should render block expressions" do
    to_handlebars("= hb 'hello' do\n  world.").should ==
      "{{#hello}}world.{{/hello}}"
  end

  it "should render expression options" do
    to_handlebars('= hb "hello",:whom => "world"').should ==
      "{{hello whom=\"world\"}}"
  end

  it "should render tripple-stash expressions" do
    to_handlebars('= hb! "hello"').should ==
      "{{{hello}}}"
  end

  it "should render tripple-stash block expressions" do
    to_handlebars("= hb! 'hello' do\n  world.").should ==
      "{{{#hello}}}world.{{{/hello}}}"
  end

  it "should render tripple-stash expression options" do
    to_handlebars('= hb! "hello",:whom => "world"').should ==
      "{{{hello whom=\"world\"}}}"
  end

  it "should not escape block contents" do
    handlebars = to_handlebars <<EOF
= hb 'if a_thing_is_true' do
  = hb 'hello'
  %a{:bind => {:href => 'aController'}}
EOF
    handlebars.should == "{{#if a_thing_is_true}}{{hello}}\n<a {{bind-attr href=\"aController\"}}></a>{{/if}}"
  end

  it "should not mark expressions as html_safe when XSS protection is disabled" do
    Haml::Util.module_eval do
      def rails_xss_safe?
        false
      end
    end
    Hamlbars::Template
    helpers = Class.new { include Haml::Helpers }.new
    helpers.hb 'some_expression'.should_not be_a(ActiveSupport::SafeBuffer)
  end

  it "should not mark expressions as html_safe when XSS protection is disabled" do
    Haml::Util.module_eval do
      def rails_xss_safe?
        true
      end
    end
    Hamlbars::Template
    helpers = Class.new { include Haml::Helpers }.new
    helpers.hb 'some_expression'.should_not be_a(ActiveSupport::SafeBuffer)
  end

end
