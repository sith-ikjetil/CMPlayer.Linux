import Foundation

/// 
/// Extracts track number from aac metadata track field.
/// 
func extractMetadataTrackNo(text: String) -> Int {
    // Define a regular expression pattern for a number or a number1/number2 format
    let pattern = "\\b(\\d+)/?\\d*\\b"
    
    // Create a regular expression object
    let regex = try? NSRegularExpression(pattern: pattern)
    
    // Search for the first match
    if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
        // Extract the matched range for the first number
        if let range = Range(match.range(at: 1), in: text) {
            return Int(String(text[range])) ?? 0
        }
    }
    
    return 0
}
/// 
/// Extracts year from aac metadata date/year fields.
/// 
func extractMetadataYear(text: String) -> Int {
    // Define a regular expression pattern for a number or a number1/number2 format
    let pattern = "\\b.*(\\d{4}).*\\b"
    
    // Create a regular expression object
    let regex = try? NSRegularExpression(pattern: pattern)
    
    // Search for the first match
    if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
        // Extract the matched range for the first number
        if let range = Range(match.range(at: 1), in: text) {
            return Int(String(text[range])) ?? 0
        }
    }
    
    return 0
}
/// 
/// 
/// - Parameter text: 
/// - Returns: 
func extractMetadataGenre(text: String) -> String {
    //
    // 1. Search for a number, assume genre index and get name from index.
    //
    let pattern1 = "\\b(\\d{1,3})\\b"
    let regex1 = try? NSRegularExpression(pattern: pattern1)
    if let match = regex1?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
        if let range = Range(match.range(at: 1), in: text) {
            if let genreId = UInt8(String(text[range])) {
                return convertId3V1GenreIndexToName(index: genreId)
            }
        }
    }

    //
    // 2. Search for a name, assume name is genre.
    //
    let pattern2 = "\\b([\\w-/ ]+)\\b"
    let regex2 = try? NSRegularExpression(pattern: pattern2)
    if let match = regex2?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
        if let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
    }

    return g_metadataNotFoundName
}

/// 
/// Converts an id3v1 genre id to a genre name.
/// - Parameter index: id3v1 genre id
/// - Returns:  genre name.
internal func convertId3V1GenreIndexToName(index: UInt8) -> String {    
    switch index {
        case 0: return "Blues"
        case 1: return "Classic Rock"
        case 2: return "Country"
        case 3: return "Dance"
        case 4: return "Disco"
        case 5: return "Funk"
        case 6: return "Grunge"
        case 7: return "Hip-Hop"
        case 8: return "Jazz"
        case 9: return "Metal"
        case 10: return "New Age"
        case 11: return "Oldies"
        case 12: return "Other"
        case 13: return "Pop"
        case 14: return "R&B"
        case 15: return "Rap"
        case 16: return "Reggae"
        case 17: return "Rock"
        case 18: return "Techno"
        case 19: return "Industrial"
        case 20: return "Alternative"
        case 21: return "Ska"
        case 22: return "Death Metal"
        case 23: return "Pranks"
        case 24: return "Soundtrack"
        case 25: return "Euro-Techno"
        case 26: return "Ambient"
        case 27: return "Trip-Hop"
        case 28: return "Vocal"
        case 29: return "Jazz+Funk"
        case 30: return "Fusion"
        case 31: return "Trance"
        case 32: return "Classical"
        case 33: return "Instrumental"
        case 34: return "Acid"
        case 35: return "House"
        case 36: return "Game"
        case 37: return "Sound Clip"
        case 38: return "Gospel"
        case 39: return "Noise"
        case 40: return "AlternRock"
        case 41: return "Bass"
        case 42: return "Soul"
        case 43: return "Punk"
        case 44: return "Space"
        case 45: return "Meditative"
        case 46: return "Instrumental Pop"
        case 47: return "Instrumental Rock"
        case 48: return "Ethnic"
        case 49: return "Gothic"
        case 50: return "Darkwave"
        case 51: return "Techno-Industrial"
        case 52: return "Electronic"
        case 53: return "Pop-Folk"
        case 54: return "Eurodance"
        case 55: return "Dream"
        case 56: return "Southern Rock"
        case 57: return "Comedy"
        case 58: return "Cult"
        case 59: return "Gangsta"
        case 60: return "Top 40"
        case 61: return "Christian Rap"
        case 62: return "Pop/Funk"
        case 63: return "Jungle"
        case 64: return "Native American"
        case 65: return "Cabaret"
        case 66: return "New Wave"
        case 67: return "Psychedelic"
        case 68: return "Rave"
        case 69: return "Showtunes"
        case 70: return "Trailer"
        case 71: return "Lo-Fi"
        case 72: return "Tribal"
        case 73: return "Acid Punk"
        case 74: return "Acid Jazz"
        case 75: return "Polka"
        case 76: return "Retro"
        case 77: return "Musical"
        case 78: return "Rock & Roll"
        case 79: return "Hard Rock"
        case 80: return "Folk"
        case 81: return "Folk-Rock"
        case 82: return "National Folk"
        case 83: return "Swing"
        case 84: return "Fast Fusion"
        case 85: return "Bebop"
        case 86: return "Latin"
        case 87: return "Revival"
        case 88: return "Celtic"
        case 89: return "Bluegrass"
        case 90: return "Avantgarde"
        case 91: return "Gothic Rock"
        case 92: return "Progressive Rock"
        case 93: return "Psychedelic Rock"
        case 94: return "Symphonic Rock"
        case 95: return "Slow Rock"
        case 96: return "Big Band"
        case 97: return "Chorus"
        case 98: return "Easy Listening"
        case 99: return "Acoustic"
        case 100: return "Humour"
        case 101: return "Speech"
        case 102: return "Chanson"
        case 103: return "Opera"
        case 104: return "Chamber Music"
        case 105: return "Sonata"
        case 106: return "Symphony"
        case 107: return "Booty Bass"
        case 108: return "Primus"
        case 109: return "Porn Groove"
        case 110: return "Satire"
        case 111: return "Slow Jam"
        case 112: return "Club"
        case 113: return "Tango"
        case 114: return "Samba"
        case 115: return "Folklore"
        case 116: return "Ballad"
        case 117: return "Power Ballad"
        case 118: return "Rhythmic Soul"
        case 119: return "Freestyle"
        case 120: return "Duet"
        case 121: return "Punk Rock"
        case 122: return "Drum Solo"
        case 123: return "A capella"
        case 124: return "Euro-House"
        case 125: return "Dance Hall"        
        case 126: return "Goa"
        case 127: return "Drum & Bass"
        case 128: return "Club-House"
        case 129: return "Hardcore"
        case 130: return "Terror"
        case 131: return "Indie"
        case 132: return "BritPop"
        case 133: return "Negerpunk"
        case 134: return "Polsk Punk"
        case 135: return "Beat"
        case 136: return "Christian Gangsta"
        case 137: return "Heavy Metal"
        case 138: return "Black Metal"
        case 139: return "Crossover"
        case 140: return "Contemporary Christian"
        case 141: return "Christian Rock"
        case 142: return "Merengue"
        case 143: return "Salsa"
        case 144: return "Trash Metal"
        case 145: return "Anime"
        case 146: return "Jpop"
        case 147: return "Synthpop"
        case 148: return "Abstract"
        case 149: return "Art Rock"
        case 150: return "Baroque"
        case 151: return "Bhangra"
        case 152: return "Big Beat"
        case 153: return "Breakbeat"
        case 154: return "Chillout"
        case 155: return "Downtempo"
        case 156: return "Dub"
        case 157: return "EBM"
        case 158: return "Eclectic"
        case 159: return "Electro"
        case 160: return "Electroclash"
        case 161: return "Emo"
        case 162: return "Experimental"
        case 163: return "Garage"
        case 164: return "Global"
        case 165: return "IDM"
        case 166: return "Illbient"
        case 167: return "Industro-Goth"
        case 168: return "Jam Band"
        case 169: return "Krautrock"
        case 170: return "Leftfield"
        case 171: return "Lounge"
        case 172: return "Math Rock"
        case 173: return "New Romantic"
        case 174: return "Nu-Breakz"
        case 175: return "Post-Punk"
        case 176: return "Post-Rock"
        case 177: return "Psytrance"
        case 178: return "Shoegaze"
        case 179: return "Space Rock"
        case 180: return "Trop Rock"
        case 181: return "World Music"
        case 182: return "Neoclassical"
        case 183: return "Audiobook"
        case 184: return "Audio Theatre"
        case 185: return "Neue Deutsche Welle"
        case 186: return "Podcast"
        case 187: return "Indie Rock"
        case 188: return "G-Funk"
        case 189: return "Dubstep"
        case 190: return "Garage Rock"
        case 191: return "Psybient"
        default: return g_metadataNotFoundName
    }
}