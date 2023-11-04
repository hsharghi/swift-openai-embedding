// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import OpenAI
import PostgresNIO
import Logging


struct Embbedder {
    var connection: PostgresConnection
    var logger: Logger
    var openAI: OpenAI
    
    init() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("No API key is set. (OPENAI_API_KEY)")
        }
        self.openAI = OpenAI(apiToken: apiKey)

        self.logger = Logger(label: "postgres-logger")
        self.logger.logLevel = .debug
        
        let config = PostgresConnection.Configuration(
            host: "localhost",
            port: 5432,
            username: "root",
            password: "hadi2400",
            database: "vectest",
            tls: .disable
        )
        let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let connection = try await PostgresConnection.connect(on: eventGroup.any(), configuration: config, id: 1, logger: logger)
        
        self.connection = connection
        
    }
    
    func embed() async throws {
        
        var i = 1
        _ = try await text.asyncForEach { string in
            print("embedding \(i) of \(text.count)")
            let result = try await openAI.embeddings(query: .init(model: .textEmbeddingAda, input: string))
            try await storeEmbedding(content: string, vector: result.data.first!.embedding)
            try await Task.sleep(for: .seconds(21))
            i += 1
        }
        
        //        print(result)
        
        
        
    }
    
    func storeEmbedding(content: String, vector: [Double]) async throws {
        let vectorString = vector.toStringVector()
        
        try await connection.query("INSERT INTO items (contents, embedding) VALUES (\(content), \(vectorString)::vector)", logger: logger)
        
    }
    
    func ask(text: String) async throws {
        let result = try await openAI.embeddings(query: .init(model: .textEmbeddingAda, input: text))
        let vector = result.data.first!.embedding
        let vectorString = vector.toStringVector()
        
        let rows = try await connection.query("SELECT id, contents, embedding::text FROM items ORDER BY embedding <-> \(vectorString)::vector LIMIT 5", logger: logger)
        for try await row in rows {
            for cell in row { 
                let tyep = cell.dataType
            }
            print(row)
        }
//
//        let query = "SELECT id, contents, embedding::text FROM items ORDER BY embedding <-> \(vectorString)::vector LIMIT 5"
////        let query = "SELECT * FROM items ORDER BY embedding <-> '\(vectorString)' LIMIT 5"
//        let rows = try await connection.query(.init(stringLiteral: query), logger: logger)
//        for try await row in rows {
//            print(row)
//        }
//
//        for try await (id, contents, embedding) in rows.decode((Int, String, [Double]).self) {
//          print(id, contents, embedding)
//        }

    }
    
    let text: [String] = [
        "Prince Rupert's drops (also known as Dutch or Batavian tears)[1][2] are toughened glass beads created by dripping molten glass into cold water, which causes it to solidify into a tadpole-shaped droplet with a long, thin tail. These droplets are characterized internally by very high residual stresses, which give rise to counter-intuitive properties, such as the ability to withstand a blow from a hammer or a bullet on the bulbous end without breaking, while exhibiting explosive disintegration if the tail end is even slightly damaged. In nature, similar structures are produced under certain conditions in volcanic lava, and are known as Pele's tears.",
        "The drops are named after Prince Rupert of the Rhine, who brought them to England in 1660, although they were reportedly being produced in the Netherlands earlier in the 17th century and had probably been known to glassmakers for much longer. They were studied as scientific curiosities by the Royal Society and the unravelling of the principles of their unusual properties probably led to the development of the process for the production of toughened glass, patented in 1874. Research carried out in the 20th and 21st centuries shed further light on the reasons for the drops' contradictory properties.",
        "Description, Prince Rupert's drops are produced by dropping molten glass drops into cold water. The glass rapidly cools and solidifies in the water from the outside inward. This thermal quenching may be described by means of a simplified model of a rapidly cooled sphere.[3] Prince Rupert's drops have remained a scientific curiosity for nearly 400 years due to two unusual mechanical properties:[4] when the tail is snipped, the drop disintegrates explosively into powder, whereas the bulbous head can withstand compressive forces of up to 664,300 newtons (67,740 kgf)",
        "The explosive disintegration arises due to multiple crack bifurcation events when the tail is cut – a single crack is accelerated in the tensile residual stress field in the center of the tail and bifurcates after it reaches a critical velocity of 1,450–1,900 metres per second (3,200–4,300 mph).[6][7] Given these high speeds, the disintegration process due to crack bifurcation can only be inferred by looking into the tail and employing high speed imaging techniques. This is perhaps why this curious property of the drops remained unexplained for centuries.[8]",
        "The second unusual property of the drops, namely the strength of the heads, is a direct consequence of large compressive residual stresses —up to 700 megapascals (100,000 psi)— that exist in the vicinity of the head's outer surface.[2] This stress distribution is measured by using glass's natural property of stress-induced birefringence and by employing techniques of 3D photoelasticity. The high fracture toughness due to residual compressive stresses makes Prince Rupert's drops one of the earliest examples of toughened glass.",
        "History It has been suggested that methods for making the drops have been known to glassmakers since the times of the Roman Empire.",
        "Sometimes attributed to Dutch inventor Cornelis Drebbel, the drops were often referred to as lacrymae Borussicae (Prussian tears) or lacrymae Batavicae (Dutch tears) in contemporary accounts.[10]",
        "Verifiable accounts of the drops from Mecklenburg in North Germany appear as early as 1625.[11] The secret of how to make them remained in the Mecklenburg area for some time, although the drops were disseminated across Europe from there, for sale as toys or curiosities.",
        "The Dutch scientist Constantijn Huygens asked Margaret Cavendish, Duchess of Newcastle to investigate the properties of the drops; her opinion after carrying out experiments was that a small amount of volatile liquid was trapped inside.[12]",
        "Although Prince Rupert did not discover the drops, he played a role in their history by bringing them to Britain in 1660. He gave them to King Charles II, who in turn delivered them in 1661 to the Royal Society (which had been created the previous year) for scientific study. Several early publications from the Royal Society give accounts of the drops and describe experiments performed.[13] Among these publications was Micrographia of 1665 by Robert Hooke, who later would discover Hooke's Law.[4] His publication laid out correctly most of what can be said about Prince Rupert's drops without a fuller understanding than existed at the time, of elasticity (to which Hooke himself later contributed) and of the failure of brittle materials from the propagation of cracks. A fuller understanding of crack propagation had to wait until the work of A. A. Griffith in 1920",
        "In 1994, Srinivasan Chandrasekar, an engineering professor at Purdue University, and Munawar Chaudhri, head of the materials group at the University of Cambridge, used high-speed framing photography to observe the drop-shattering process and concluded that while the surface of the drops experiences highly compressive stresses, the inside experiences high tension forces, creating a state of unequal equilibrium which can easily be disturbed by breaking the tail. However, this left the question of how the stresses are distributed throughout a Prince Rupert's drop.",
        "In a further study published in 2017, the team collaborated with Hillar Aben, a professor at Tallinn University of Technology in Estonia using a transmission polariscope to measure the optical retardation of light from a red LED as it travelled through the glass drop, and used the data to construct the stress distribution throughout the drop. This showed that the heads of the drops have a much higher surface compressive stress than previously thought at up to 700 megapascals (100,000 psi), but that this surface compressive layer is also thin, only about 10% of the diameter of the head of a drop. This gives the surface a high fracture strength which means that it is necessary to create a crack that enters the interior tension zone in order to break the droplet. As cracks on the surface tend to grow parallel to the surface, they cannot enter the tension zone but a disturbance in the tail allows cracks to enter the tension zone.[15]",
        "A scholarly account of the early history of Prince Rupert's drops is given in the Notes and Records of the Royal Society of London, where much of the early scientific study of the drops was performed.[9]",
        "Scientific uses The process for the production of toughened glass by quenching was probably inspired by the study of the drops, as it was patented in England by Parisian Francois Barthelemy Alfred Royer de la Bastie, in 1874, just one year after V. De Luynes had published accounts of his experiments with them.",
        "It has been known since at least the 19th century that formations similar to Prince Rupert's drops are produced under certain conditions in volcanic lava.[16] More recently researchers at the University of Bristol and the University of Iceland have studied the glass particles produced by explosive fragmentation of Prince Rupert's drops in the laboratory to better understand magma fragmentation and ash formation driven by stored thermal stresses in active volcanoes.",
        "Literary references Because of their use as a party piece, Prince Rupert's drops became widely known in the late 17th century—far more than today. It can be seen that educated people (or those in \"society\") were expected to be familiar with them, from their use in the literature of the day. Samuel Butler used them as a metaphor in his poem Hudibras in 1663,[18][19] and Pepys refers to them in his diary.",
        "The drops were immortalized in a verse of the anonymous Ballad of Gresham College (1663): And that which makes their Fame ring louder, With much adoe they shew'd the King To make glasse Buttons turn to powder, If off the[m] their tayles you doe but wring. How this was donne by soe small Force Did cost the Colledg a Month's discourse.",
        "Diarist George Templeton Strong wrote (volume 4, p. 122) of a hazardous sudden breaking up of pedestrian-bearing ice in New York City's East River during the winter of 1867 that \"The ice flashed into fragments all at once like a Prince Rupert's drop.\"",
        "Alfred Jarry's 1902 novel Supermale makes reference to the drops in an analogy for the molten glass drops falling from a failed device meant to pass eleven thousand volts of electricity through the supermale's body.",
        "Sigmund Freud, discussing the dissolution of military groups in Group Psychology and the Analysis of the Ego (1921), notes the panic that results from the loss of the leader: \"The group vanishes in dust, like a Prince Rupert's drop when its tail is broken off.\"",
        "E. R. Eddison's 1935 novel Mistress of Mistresses references Rupert's drops in the last chapter as Fiorinda sets off a whole set of them.",
        "In the 1940 detective novel There Came Both Mist and Snow by Michael Innes (J. I. M. Stewart), a character incorrectly refers to them as \"Verona drops\"; the error is corrected towards the end of the novel by the detective Sir John Appleby.",
        "In his 1943 novella Conjure Wife, Fritz Leiber uses Prince Rupert drops as a metaphor for the volatility of several characters' personalities. These small-town college faculty people seem to be placid and impervious, but \"explode\" at a mere \"flick of the filament\".",
        "Peter Carey devotes a chapter to the drops in his 1988 novel Oscar and Lucinda.",
        "The title-giving suite to progressive rock band King Crimson's 1970 third studio album Lizard includes both parts referring to a fictionalised version of Prince Rupert as well as an extended section called \"The Battle of Glass Tears\".",
    ]
}

let embedder = try await Embbedder()
//try await embedder.embed()

try await embedder.ask(text: "how prince rupret drop is created?")

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}

extension Array where Element == Double {
    func toStringVector() -> String {
        return  "[" +
        self.map { "\($0)" }.joined(separator: ",") +
        "]"
    }
}

