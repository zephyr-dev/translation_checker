class TranslationChecker < Struct.new(:language)
  def compare_with(other_checker)
    {
      missing_keys: missing_keys(other_checker),
      orphaned_keys: orphaned_keys(other_checker),
      missing_interpolations: missing_interpolations(other_checker),
      orphaned_interpolations: orphaned_interpolations(other_checker)
    }
  end

  # {
  #   'materialized.path.to.key': [:variable_one, :variable_two]
  # }
  def interpolation_keys
    @_interpolation_keys ||= Hash[
      translations.map do |key, value|
        [key, value.to_s.scan(/%{(.*?)}/).flatten.sort.uniq]
      end.select do |key, value|
        value.present?
      end.sort
    ]
  end

  def translation_keys
    @_translation_keys ||= translations.keys
  end

  def translations
    @_translations ||= parsed.inject({}) do |memo, (key, value)|
      memo.merge extract_translations([key], value)
    end
  end

  def orphaned_keys(other_checker)
    translation_keys - other_checker.translation_keys
  end

  def missing_keys(other_checker)
    other_checker.translation_keys - translation_keys
  end

  # Ones that are in ENGLISH (i.e. other_checker) but not me (i.e. Spanish)
  def missing_interpolations(other_checker)
    other_checker.interpolation_keys.select do |key, value|
      interpolation_keys[key] != value
    end.select do |key, value|
      !missing_keys(other_checker).include?(key) && !orphaned_keys(other_checker).include?(key)
    end
  end

  # Ones that are in SPANISH (i.e. me) but not ENGLISH (i.e. other_checker)
  def orphaned_interpolations(other_checker)
    interpolation_keys.select do |key, value|
      other_checker.interpolation_keys[key] != value
    end.select do |key, value|
      !missing_keys(other_checker).include?(key) && !orphaned_keys(other_checker).include?(key)
    end
  end

  private

  def parsed
    @_parsed ||= YAML.load_file(locales_dir.join "phrase.#{language}.yml")[language.to_s]
  end

  def locales_dir
    Rails.root.join('config', 'locales')
  end

  def extract_translations(key_path, children)
    if children.is_a?(String) || children.is_a?(Numeric) || children.nil? || children.is_a?(Symbol)
      { key_path.join('.') => children }

    elsif children.is_a? Array
      children.each_with_index.inject({}) do |memo, (value, index)|
        memo.merge extract_translations([*key_path, index], value)
      end

    elsif children.is_a?(Hash)
      children.inject({}) do |memo, (key, grandchildren)|
        memo.merge extract_translations([*key_path, key], grandchildren)
      end
    else
      raise "Translations file phrase.#{language}.yml contains unexpected type: #{children.class} for key path #{key_path.join('.')}. Must only contain hashes and strings."
    end
  end

end

