require File.expand_path("../../test_helper", __FILE__)

require "capybara/dsl"

describe Flipflop do
  include Capybara::DSL

  describe "without translations" do
    before do
      @app = TestApp.new
    end

    after do
      @app.unload!
    end

    subject do
      @app
    end

    describe "without features" do
      before do
        visit "/flipflop"
      end

      it "should show feature header" do
        assert_equal "My Test App Features", first("h1").text
      end

      it "should show feature table with header" do
        assert_equal ["Cookie", "Active record", "Default"],
          all("thead th").map(&:text)[3..-1]
      end

      it "should show no features" do
        assert all("tbody tr").empty?
      end
    end

    describe "with features" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          feature :world_domination, description: "Try and take over the world!"
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should show feature header" do
        assert_equal "My Test App Features", first("h1").text
      end

      it "should show feature names" do
        assert_equal ["World domination", "Shiny things"],
          all("tr[data-feature] td.name").map(&:text)
      end

      it "should show feature descriptions" do
        assert_equal ["Try and take over the world!", "Shiny things."],
          all("tr[data-feature] td.description").map(&:text)
      end

      it "should not show feature group" do
        assert_equal [], all("tr h2").map(&:text)
      end
    end

    describe "with grouped features" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          group "world" do
            feature :world_domination, description: "Try and take over the world!"
          end
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should show feature header" do
        assert_equal "My Test App Features", first("h1").text
      end

      it "should show feature names" do
        assert_equal ["World domination", "Shiny things"],
          all("tr[data-feature] td.name").map(&:text)
      end

      it "should show feature descriptions" do
        assert_equal ["Try and take over the world!", "Shiny things."],
          all("tr[data-feature] td.description").map(&:text)
      end

      it "should show feature groups" do
        assert_equal ["World", "Other features"], all("tr h2").map(&:text)
      end
    end

    describe "with cookie strategy" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          feature :world_domination, description: "Try and take over the world!"
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should enable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "on"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "on", first("td.status").text
          assert_equal "on", first("td[data-strategy=cookie] button.active").text
        end
      end

      it "should disable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "off"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "off", first("td.status").text
          assert_equal "off", first("td[data-strategy=cookie] button.active").text
        end
      end

      it "should enable and clear feature" do
        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "on"
        end

        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "clear"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "off", first("td.status").text
          refute has_selector?("td[data-strategy=cookie] button.active")
        end
      end

      it "should enable feature after in spite of redefinition and reordering" do
        Flipflop::FeatureSet.current.instance_variable_set(:@strategies, {})
        Module.new do
          extend Flipflop::Configurable
          strategy :active_record, description: "Store in database."
          strategy :cookie, description: "Store in cookie."
        end

        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "on"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "on", first("td.status").text
          assert_equal "on", first("td[data-strategy=cookie] button.active").text
        end
      end
    end

    describe "with active record strategy" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          feature :world_domination, description: "Try and take over the world!"
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should enable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "on"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "on", first("td.status").text
          assert_equal "on", first("td[data-strategy=active-record] button.active").text
        end
      end

      it "should disable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "off"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "off", first("td.status").text
          assert_equal "off", first("td[data-strategy=active-record] button.active").text
        end
      end

      it "should enable and clear feature" do
        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "on"
        end

        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "clear"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "off", first("td.status").text
          refute has_selector?("td[data-strategy=active-record] button.active")
        end
      end

      it "should enable feature after in spite of redefinition and reordering" do
        Flipflop::FeatureSet.current.instance_variable_set(:@strategies, {})
        Module.new do
          extend Flipflop::Configurable
          strategy :active_record, description: "Store in database."
          strategy :cookie, description: "Store in cookie."
        end

        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "on"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "on", first("td.status").text
          assert_equal "on", first("td[data-strategy=active-record] button.active").text
        end
      end
    end

    describe "with hidden strategy" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@strategies, {})
        Module.new do
          extend Flipflop::Configurable
          strategy :query_string, hidden: true
        end

        visit "/flipflop"
      end

      it "should not show hidden strategy" do
        assert_equal [], all("thead th").map(&:text)[3..-1]
      end
    end
  end

  describe "with translations" do
    before do
      @app = TestApp.new([
        TestLocaleGenerator,
      ])

      I18n.locale = :nl
    end

    after do
      @app.unload!
    end

    subject do
      @app
    end

    describe "without features" do
      before do
        visit "/flipflop"
      end

      it "should show feature header" do
        assert_equal "My Test App Functionaliteiten", first("h1").text
      end

      it "should show feature table with header" do
        assert_equal ["Koekje", "Actief archief", "Standaard"],
          all("thead th").map(&:text)[3..-1]
      end

      it "should show no features" do
        assert all("tbody tr").empty?
      end
    end

    describe "with features" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          feature :world_domination, description: "Try and take over the world!"
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should show feature header" do
        assert_equal "My Test App Functionaliteiten", first("h1").text
      end

      it "should show feature names" do
        assert_equal ["Wereldoverheersing", "Glimmende dingetjes"],
          all("tr[data-feature] td.name").map(&:text)
      end

      it "should show feature descriptions" do
        assert_equal ["Neem de wereld over!", "Glimmende dingetjes."],
          all("tr[data-feature] td.description").map(&:text)
      end

      it "should not show feature group" do
        assert_equal [], all("tr h2").map(&:text)
      end
    end

    describe "with grouped features" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          group "world" do
            feature :world_domination, description: "Try and take over the world!"
          end
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should show feature header" do
        assert_equal "My Test App Functionaliteiten", first("h1").text
      end

      it "should show feature names" do
        assert_equal ["Wereldoverheersing", "Glimmende dingetjes"],
          all("tr[data-feature] td.name").map(&:text)
      end

      it "should show feature descriptions" do
        assert_equal ["Neem de wereld over!", "Glimmende dingetjes."],
          all("tr[data-feature] td.description").map(&:text)
      end

      it "should show feature groups" do
        assert_equal ["Wereld", "Overige functionaliteiten"], all("tr h2").map(&:text)
      end
    end

    describe "with cookie strategy" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          feature :world_domination, description: "Try and take over the world!"
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should enable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "aan"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "aan", first("td.status").text
          assert_equal "aan", first("td[data-strategy=cookie] button.active").text
        end
      end

      it "should disable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "uit"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "uit", first("td.status").text
          assert_equal "uit", first("td[data-strategy=cookie] button.active").text
        end
      end

      it "should enable and clear feature" do
        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "aan"
        end

        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "wissen"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "uit", first("td.status").text
          refute has_selector?("td[data-strategy=cookie] button.active")
        end
      end

      it "should enable feature after in spite of redefinition and reordering" do
        Flipflop::FeatureSet.current.instance_variable_set(:@strategies, {})
        Module.new do
          extend Flipflop::Configurable
          strategy :active_record, description: "Store in database."
          strategy :cookie, description: "Store in cookie."
        end

        within("tr[data-feature=world-domination] td[data-strategy=cookie]") do
          click_on "aan"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "aan", first("td.status").text
          assert_equal "aan", first("td[data-strategy=cookie] button.active").text
        end
      end
    end

    describe "with active record strategy" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@features, {})
        Flipflop::FeatureSet.current.instance_variable_set(:@facade, Class.new.new)
        Module.new do
          extend Flipflop::Configurable
          feature :world_domination, description: "Try and take over the world!"
          feature :shiny_things, default: true
        end

        Capybara.current_session.driver.browser.clear_cookies
        Flipflop::Feature.delete_all

        visit "/flipflop"
      end

      it "should enable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "aan"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "aan", first("td.status").text
          assert_equal "aan", first("td[data-strategy=active-record] button.active").text
        end
      end

      it "should disable feature" do
        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "uit"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "uit", first("td.status").text
          assert_equal "uit", first("td[data-strategy=active-record] button.active").text
        end
      end

      it "should enable and clear feature" do
        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "aan"
        end

        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "wissen"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "uit", first("td.status").text
          refute has_selector?("td[data-strategy=active-record] button.active")
        end
      end

      it "should enable feature after in spite of redefinition and reordering" do
        Flipflop::FeatureSet.current.instance_variable_set(:@strategies, {})
        Module.new do
          extend Flipflop::Configurable
          strategy :active_record, description: "Store in database."
          strategy :cookie, description: "Store in cookie."
        end

        within("tr[data-feature=world-domination] td[data-strategy=active-record]") do
          click_on "aan"
        end

        within("tr[data-feature=world-domination]") do
          assert_equal "aan", first("td.status").text
          assert_equal "aan", first("td[data-strategy=active-record] button.active").text
        end
      end
    end

    describe "with hidden strategy" do
      before do
        Flipflop::FeatureSet.current.instance_variable_set(:@strategies, {})
        Module.new do
          extend Flipflop::Configurable
          strategy :query_string, hidden: true
        end

        visit "/flipflop"
      end

      it "should not show hidden strategy" do
        assert_equal [], all("thead th").map(&:text)[3..-1]
      end
    end
  end
end
