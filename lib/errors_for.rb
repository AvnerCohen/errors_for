# Disclaimer - Code is copied as is from rails 2.3.10, and is only intended to act as a polyfill for error_messages_for() usage
# In projects migrating from old rails env
# --@avnerner (israbirding@gmail.com)
# Returns a string with a <tt>DIV</tt> containing all of the error messages for the objects located as instance variables by the names
# given.  If more than one object is specified, the errors for the objects are displayed in the order that the object names are
# provided.
#
# This <tt>DIV</tt> can be tailored by the following options:
#
# * <tt>:header_tag</tt> - Used for the header of the error div (default: "h2").
# * <tt>:id</tt> - The id of the error div (default: "errorExplanation").
# * <tt>:class</tt> - The class of the error div (default: "errorExplanation").
# * <tt>:object</tt> - The object (or array of objects) for which to display errors,
#   if you need to escape the instance variable convention.
# * <tt>:object_name</tt> - The object name to use in the header, or any text that you prefer.
#   If <tt>:object_name</tt> is not set, the name of the first object will be used.
# * <tt>:header_message</tt> - The message in the header of the error div.  Pass +nil+
#   or an empty string to avoid the header message altogether. (Default: "X errors
#   prohibited this object from being saved").
# * <tt>:message</tt> - The explanation message after the header message and before
#   the error list.  Pass +nil+ or an empty string to avoid the explanation message
#   altogether. (Default: "There were problems with the following fields:").
#
# To specify the display for one object, you simply provide its name as a parameter.
# For example, for the <tt>@user</tt> model:
#
#   error_messages_for 'user'
#
# To specify more than one object, you simply list them; optionally, you can add an extra <tt>:object_name</tt> parameter, which
# will be the name used in the header message:
#
#   error_messages_for 'user_common', 'user', :object_name => 'user'
#
# If the objects cannot be located as instance variables, you can add an extra <tt>:object</tt> parameter which gives the actual
# object (or array of objects to use):
#
#   error_messages_for 'user', :object => @question.user
#
# NOTE: This is a pre-packaged presentation of the errors with embedded strings and a certain HTML structure. If what
# you need is significantly different from the default presentation, it makes plenty of sense to access the <tt>object.errors</tt>
# instance yourself and set it up. View the source of this method to see how easy it is.
def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys

        if object = options.delete(:object)
          objects = Array.wrap(object)
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end

        count  = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          options[:object_name] ||= params.first

          I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
            header_message = if options.include?(:header_message)
              options[:header_message]
            else
              object_name = options[:object_name].to_s
              object_name = I18n.t(object_name, :default => object_name.gsub('_', ' '), :scope => [:activerecord, :models], :count => 1)
              locale.t :header, :count => count, :model => object_name
            end
            message = options.include?(:message) ? options[:message] : locale.t(:body)
            error_messages = objects.sum {|object| object.errors.full_messages.map {|msg| content_tag(:li, ERB::Util.html_escape(msg)) } }.join.html_safe

            contents = ''
            contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
            contents << content_tag(:p, message) unless message.blank?
            contents << content_tag(:ul, error_messages)

            content_tag(:div, contents.html_safe, html)
          end
        else
          ''
        end
      end