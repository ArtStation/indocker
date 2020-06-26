class Indocker::ContextArgs
  attr_reader :parent, :name

  def initialize(name, context_args, parent, container = nil)
    @name = name
    @parent = parent
    @container = container
    @context_args = context_args
  end

  def method_missing(name, *args)
    if args.size > 0
      raise ArgumentError.new("context args does not accept any arguments")
    end

    value = @context_args.fetch(name) do
      Indocker.logger.warn("build arg '#{format_arg(name)}' is not defined#{@container ? " for container :#{@container.name}" : ""}")
      Indocker.logger.warn("available args: #{@context_args.inspect}")
    end

    if value.is_a?(Hash)
      Indocker::ContextArgs.new(name, value, self, @container)
    else
      value
    end
  end

  private

  def format_arg(name)
    string = name
    parent = @parent

    while parent do
      name = parent.name
      string = "#{name}.#{string}" if name
      parent = parent.parent
      break if !parent
    end

    string
  end
end