local msg = require 'mp.msg'

function mkmetatable()
	m = {}
	for i = 0, mp.get_property("metadata/list/count") - 1 do
		p = "metadata/list/"..i.."/"
		m[mp.get_property(p.."key")] = mp.get_property(p.."value")
	end
	return m
end

function scrobble(artist, title, album, length)
	mp.resume_all()
	if artist and title then
		msg.info(string.format("Scrobbling %s - %s", artist, title))
		if not album then
			album = ""
		end
		if not length then
			length = 180	-- FIXME the old API sucks: it returns OK if the length is not specified/is 0/is -1, but doesn't scrobble anything.
		end

		-- Parameter escaping function. Works with POSIX shells; idk if there's a better way to call stuff portably in Lua.
		function esc(s)
			return string.gsub(s, "'", "'\\''")
		end

		-- Using https://github.com/l29ah/w3crapcli/blob/master/last.fm/lastfm.pl
		os.execute(string.format("lastfm.pl '%s' '%s' '%s' %d", esc(artist), esc(title), esc(album), length))
	end
end

function on_metadata()
	t = mkmetatable()["icy-title"]
	-- TODO better magic
	artist, title = string.gmatch(t, "(.+) %- (.+)")()
	scrobble(artist, title, nil, nil)
end

function on_playback()
	m = mkmetatable()
	length = mp.get_property("length")
	if length and tonumber(length) < 30 then return end	-- last.fm doesn't allow scrobbling short tracks
	artist = m["artist"]
	if not artist then
		artist = m["ARTIST"]
	end
	album = m["album"]
	if not album then
		album = m["ALBUM"]
	end
	title = m["title"]
	if not title then
		title = m["TITLE"]
	end
	scrobble(artist, title, album, length)
end

mp.register_event("metadata-update", on_metadata)
mp.register_event("file-loaded", on_playback)
