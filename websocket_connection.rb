class WebSocketConnection

  OPCODE_TEXT = 0x01

  attr_reader :socket

  def initialize(socket)
    @socket = socket
  end

  # parse bytes of a frame and yield message in application thread
  def recv
    # the 0th item determines message completeness and content type
    # 10000001 is complete and content type = text
    fin_and_opcode = socket.read(1).bytes[0]

    # the second byte determines if the message is masked and content length
    # 10000101 is masked with a length of X
    mask_and_length_indicator = socket.read(1).bytes[0]
    length_indicator = mask_and_length_indicator - 128 # remove first mask bit

    # get the content length
    length =  get_content_length(length_indicator)

    # mask key is the next 4 bites
    keys = socket.read(4).bytes

    # content bytes using content length we extracted
    encoded = socket.read(length).bytes
    decoded = decode_encoded_content(encoded, keys)

    # turn the decoded message into a string and return it
    decoded.pack("c*")
  end

  def decode_encoded_content(encoded, keys)
    return encoded.each_with_index.map do |byte, index|
      # loop through the bytes XORing the octet with the (i MOD 4)th octet
      # of the mask. Defined in the specification - https://tools.ietf.org/html/rfc6455#page-33
      byte ^ keys[index % 4]
    end
  end

  def get_content_length(length_indicator)
    length =  if length_indicator <= 125
                # length_indicator is under 125 so it
                # corresponds to content length
                length_indicator
              elsif length_indicator == 126
                # length_indicator is 126 so the
                # next two bytes need to be parsed into 16-bit unsigned
                # integer to get numeric value of length
                # Ruby Array#unpack with 'n' will give us 16-bit unsigned integer
                socket.read(2).unpack("n")[0]
              else
                # if length_indicator is 127, the next 8 bytes need to be parsed
                # into a 64-bit unsigned integer to get the length. "Q>" is passed
                # to unpack to indicate this
                socket.read(8).unpack("Q>")[0]
              end
    return length
  end

  def send(message)
    bytes = [0x80 | OPCODE_TEXT]
    size = message.bytesize

    bytes +=  if size <= 125
                # concatenate to byte array
                [size]
              elsif size <= 2**16
                # if we can fit it in two bytes pack into unsigned 16-bit
                # integer. Append 126 to act as length indicator for reciever
                [126] + [size].pack("n").bytes
              else
                # use 64-bit unsigned integer and prepend with 127
                [127] + [size].pack("Q>").bytes
              end

    bytes += message.bytes
    data = bytes.pack("C*")
    socket << data
  end
end
