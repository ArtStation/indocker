class Indocker::HashMerger
  def self.deep_merge(source, target)
    merger = proc { |key, v1, v2|
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2
    }

    source.merge(target, &merger)
  end
end
