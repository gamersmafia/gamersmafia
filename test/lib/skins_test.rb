# -*- encoding : utf-8 -*-
require 'test_helper'

class SkinsTest < ActiveSupport::TestCase
  test "all_color_generators_should_run_with_default_parameters" do
   (Skins::ColorGenerators.constants - [:AbstractGenerator]).each do |cg|
      assert Skins::ColorGenerators.const_get(cg).process({}) != ''
    end
  end

  test "hsv_and_rgb_conversions_should_work" do
    assert_equal [0.25, 0.5, 0.5], Skins::ColorGenerators::hsv_to_rgb(0.5, 0.5, 0.5)
    assert_equal [0.5, 0.5, 0.5],  Skins::ColorGenerators::rgb_to_hsv(0.25, 0.5, 0.5)

  end

  test "rgbhex_to_rgb" do
    assert_equal [1.0,1.0,1.0], Skins::ColorGenerators::rgbhex_to_rgb('ffffff')
    assert_equal [0,0,0], Skins::ColorGenerators::rgbhex_to_rgb('000000')
  end

  test "all_color_generators_should_give_all_strict_colors" do
    sorted_strict_colors = Skins::COLORS_STRICT.keys
     (Skins::ColorGenerators.constants - [:AbstractGenerator]).sort.each do |cg|
      sg_colors = Skins::ColorGenerators.const_get(cg).get_colors
      undefined_keys = []
      sorted_strict_colors.each do |st_key|
        undefined_keys<< st_key unless sg_colors[st_key]
      end
      assert_equal 0, undefined_keys.size, "#{cg} no define #{undefined_keys.join("\n")}"
    end
  end

  test "processing_core_css_should_work" do
    # TODO: Hacerlo con todos los generadores de colores
    css = Skins::ColorGenerators::BlackSpot.process(Skins::ColorGenerators::BlackSpot::DEF_OPTIONS)
    assert_nil Regexp.new((Regexp.escape('${pat}').gsub('pat', '[a-z_-]+'))) =~ css, css
    assert !css.include?('${'), css
  end

  test "css_regexp_optional_is_ok" do
    re = Skins::ColorGenerators::AbstractGenerator.get_re_for_key('sample')
    css_sample1 = <<-END
body {
color: red;
}

.module {
background-color: \#${sample};
}
    END

    css_sample_without_opt = <<-END
body {
color: red;
}

.module {

}
    END

    assert_not_nil re =~ css_sample1
    assert_equal css_sample_without_opt, css_sample1.gsub(re, '')
  end

  test "skin_not_used_should_return_count_0" do
    s1 = Skin.find(1)
    assert_equal s1.used_by_users_count, 0
  end

  test "skin_used_shouldnt_return_count_0" do
    s1 = Skin.find(1)
    u1 = User.find(1)
    u2 = User.find(2)
    u1.pref_skin = s1.id
    u2.pref_skin = s1.id
    assert_equal s1.used_by_users_count, 2
  end
end
