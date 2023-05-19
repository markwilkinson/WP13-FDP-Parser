require 'rest-client'
require 'json'

@serverURL = "http://localhost:7070"

def set_headers
  return if $headers

  puts ENV.fetch("FDPUSER", nil)
  puts ENV.fetch("FDPPASS", nil)
  payload = '{ "email": "' + ENV.fetch("FDPUSER", nil) + '", "password": "' + ENV.fetch("FDPPASS", nil) + '" }'
  resp = RestClient.post("#{@serverURL}/tokens", payload, headers = { content_type: "application/json" })
  $token = JSON.parse(resp.body)["token"]
  puts $token
  $headers = { content_type: "text/turtle", authorization: "Bearer #{$token}", accept: "text/turtle" }
end

set_headers
f = File.open('./to_delete', 'r')
lines = f.readlines
f.close

lines.each do |location|
  location.strip!
  warn "deleting #{location}"
  begin
    resp = RestClient.delete("#{location}", headers = { authorization: "Bearer #{$token}", content_type: "application/json" })
    warn resp.inspect
  rescue
    next
  end

end