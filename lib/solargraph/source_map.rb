module Solargraph
  class SourceMap
    autoload :Mapper,        'solargraph/source_map/mapper'
    autoload :Fragment,      'solargraph/source_map/fragment'
    autoload :Chain,         'solargraph/source_map/chain'
    autoload :Clip,          'solargraph/source_map/clip'
    autoload :SourceChainer, 'solargraph/source_map/source_chainer'
    autoload :NodeChainer,   'solargraph/source_map/node_chainer'
    autoload :Completion,    'solargraph/source_map/completion'

    attr_reader :source

    attr_reader :pins

    attr_reader :locals

    attr_reader :requires

    attr_reader :symbols

    def initialize source, pins, locals, requires, symbols, string_ranges, comment_ranges
      # [@source, @pins, @locals, @requires, @symbols, @string_ranges, @comment_ranges]
      @source = source
      @pins = pins
      @locals = locals
      @requires = requires
      @symbols = symbols
      @string_ranges = string_ranges
      @comment_ranges = comment_ranges
    end

    def filename
      source.filename
    end

    def code
      source.code
    end

    # @param position [Position]
    # @return [Boolean]
    def string_at? position
      string_ranges.each do |range|
        return true if range.contain?(position)
        break if range.last.line > position.line
      end
      false
    end

    # @param position [Position]
    # @return [Boolean]
    def comment_at? position
      comment_ranges.each do |range|
        return true if range.contain?(position)
        break if range.ending.line > position.line
      end
      false
    end

    # @param position [Position]
    # @return [Solargraph::SourceMap::Fragment]
    def fragment_at position
      Fragment.new(self, position)
    end

    # @param source [Source]
    # @return [SourceMap]
    def self.map source
      result = SourceMap::Mapper.map(source)
      new(source, *result)
    end

    def locate_named_path_pin line, character
      _locate_pin line, character, Pin::NAMESPACE, Pin::METHOD
    end

    def locate_block_pin line, character
      _locate_pin line, character, Pin::NAMESPACE, Pin::METHOD, Pin::BLOCK
    end

    private

    # @return [Array<Range>]
    attr_reader :string_ranges

    # @return [Array<Range>]
    attr_reader :comment_ranges

    def _locate_pin line, character, *kinds
      position = Position.new(line, character)
      found = nil
      pins.each do |pin|
        found = pin if (kinds.empty? or kinds.include?(pin.kind)) and pin.location.range.contain?(position)
        break if pin.location.range.start.line > line
      end
      # @todo Assuming the root pin is always valid
      found || pins.first
    end
  end
end
