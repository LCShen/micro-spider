module SpiderCore
  module FieldDSL

    # Get a field on current page.
    #
    # @param display [String] display name
    def field(display, pattern, opts = {}, &block)
      kind = opts[:kind] || :css
      actions << lambda {
        action_for(:field, {display: display, pattern: pattern, kind: kind}, opts, &block)
      }
    end

    def css_field(display, pattern, opts = {}, &block)
      field(display, pattern, opts.merge(kind: :css), &block)
    end

    def xpath_field(display, pattern, opts = {}, &block)
      field(display, pattern, opts.merge(kind: :xpath), &block)
    end

    def fields(display, pattern, opts = {}, &block)
      kind = opts[:kind] || :css
      actions << lambda {
        action_for(:fields, {display: display, pattern: pattern, kind: kind}, opts, &block)
      }
    end

    def css_fields(display, pattern, opts = {}, &block)
      fields(display, pattern, opts.merge(kind: :css), &block)
    end

    def xpath_fields(display, pattern, opts = {}, &block)
      fields(display, pattern, opts.merge(kind: :xpath), &block)
    end

    protected
    def handle_element(element)
      if element && element.respond_to?(:text)
        element.text
      else
        element
      end
    end

    def handle_elements(elements, &block)
      if elements.respond_to?(:map) && block_given?
        elements.map { |element| yield(element) }.force
      elsif elements.respond_to?(:map)
        elements.map { |element| handle_element(element) }.force
      elsif block_given?
        yield(elements)
      else
        handle_element(elements)
      end
    end

    def action_for(action, action_opts = {}, opts = {}, &block)
      begin
        logger.info "Start to get `#{action_opts[:pattern]}` displayed `#{action_opts[:display]}`."

        elements = case action
        when :field
          scan_first(action_opts[:kind], action_opts[:pattern])
        when :fields
          scan_all(action_opts[:kind], action_opts[:pattern], opts).lazy
        else
          raise 'Unknow action.'
        end

        make_field_result( action_opts[:display], handle_elements(elements, &block) )
      rescue Exception => err
        logger.fatal("Caught exception when get `#{action_opts[:pattern]}`.")
        logger.fatal(err)
      end
    end

    def make_field_result(display, field)
      current_location[:field] ||= []
      current_location[:field] << {display => field}
    end

  end
end
