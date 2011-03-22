module Routo

  class Message

    attr_accessor :text

    def initialize text
      @text = text
      generate_mess_id
    end

    def send_sms *numbers
      options = numbers.last.is_a?(Hash) ? numbers.last : {}
      recipients = numbers.map{|n| Number.new(n)}
      parse_response(Net::HTTP.post_form(URI.parse(Routo.http_api_url), params(*recipients, options)))
    end

    private

    def params *number_objects, options
      {:user => Routo.username,
       :pass => URI.encode(Routo.password),
       :number => number_objects.map(&:number).join(','),
       :ownnum => Routo.ownnum,
       :message => URI.encode(@text),
       :type => Routo.type,
       :delivery => Routo.delivery,
       :mess_id => @mess_id}.merge(options)
    end

    def generate_mess_id
      chars = ("A".."Z").to_a + ("0".."9").to_a
      @mess_id = Array.new(30){||chars[rand(chars.size)]}.join
    end

    def parse_response rep
      Rails.logger.debug "body: "+rep.body.inspect
      Rails.logger.debug "msg: "+rep.message.inspect
      case rep.body
        when /success/i         then return true
        when /error/i           then raise Routo::Exception::Error.new(rep.body)
        when /auth_failed/i     then raise Routo::Exception::AuthFailed.new(rep.body)
        when /wrong_number/i    then raise Routo::Exception::WrongNumber.new(rep.body)
        when /not_allowed/i     then raise Routo::Exception::NotAllowed.new(rep.body)
        when /too_many_numbers/i then raise Routo::Exception::TooManyNumbers.new(rep.body)
        when /no_message/i      then raise Routo::Exception::NoMessage.new(rep.body)
        when /too_long/i        then raise Routo::Exception::TooLong.new(rep.body)
        when /wrong_type/i      then raise Routo::Exception::WrongType.new(rep.body)
        when /wrong_message/i   then raise Routo::Exception::WrongMessage.new(rep.body)
        when /wrong_format/i    then raise Routo::Exception::WrongFormat.new(rep.body)
        when /bad_operator/i    then raise Routo::Exception::BadOperator.new(rep.body)
        when /failed/i          then raise Routo::Exception::Failed.new(rep.body)
        when /sys_error/i       then raise Routo::Exception::SystemError.new(rep.body)
        when /no credits left/i then raise Routo::Exception::NoCreditsLeft.new(rep.body)
        else raise Routo::Exception::Base.new(rep.body)
      end
    end

  end

end