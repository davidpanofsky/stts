//
//  GoogleCloudPlatform.swift
//  stts
//

import Kanna

class GoogleCloudPlatform: Service {
    fileprivate static var statuses: [String : ServiceStatus] = [:]
    private static var callbacks: [() -> Void] = []
    private static var lastUpdateTime: TimeInterval = 0
    private static var currentlyReloading: Bool = false
    fileprivate static var loadErrorMessage: String?

    override var url: URL { return URL(string: "https://status.cloud.google.com")! }

    static func _fail(_ error: Error?) {
        self.loadErrorMessage = error?.localizedDescription ?? "Unexpected error"
    }

    static func _fail(_ message: String) {
        self.loadErrorMessage = message
    }

    static func status(for service: GoogleCloudPlatform, callback: @escaping () -> Void) {
        callbacks.append(callback)

        guard !currentlyReloading else { return }
        guard Date.timeIntervalSinceReferenceDate - lastUpdateTime >= 60 else {
            callbacks.forEach { $0() }
            callbacks = []
            return
        }

        self.currentlyReloading = true

        URLSession.shared.dataTask(with: URL(string: "https://status.cloud.google.com")!) { data, _, error in
            GoogleCloudPlatform.statuses = [:]

            guard let data = data else {
                self.loadErrorMessage = error?.localizedDescription ?? "Unexpected error"
                return
            }

            guard let body = String(data: data, encoding: .utf8) else { return _fail("Unreadable response") }
            guard let doc = HTML(html: body, encoding: .utf8) else { return _fail("Couldn't parse response") }

            for tr in doc.css(".timeline tr") {
                guard let name = tr.css(".service-status").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }

                var status: ServiceStatus = .undetermined
                if tr.css(".end-bubble.ok").count > 0 {
                    status = .good
                } else if tr.css(".end-bubble.medium").count > 0 {
                    status = .minor
                } else if tr.css(".end-bubble.high").count > 0 {
                    status = .major
                }

                statuses[name] = status
            }

            callbacks.forEach { $0() }
            callbacks = []

            self.currentlyReloading = false
            }.resume()
    }

    override func updateStatus(callback: @escaping (Service) -> Void) {
        GoogleCloudPlatform.status(for: self) { [weak self] in
            guard let selfie = self else { return }

            if let status = GoogleCloudPlatform.statuses[selfie.name] {
                self?.status = status

                switch status {
                case .good: self?.message = "Normal Operations"
                case .minor: self?.message = "Service Disruption"
                case .major: self?.message = "Service Outage"
                default: self?.message = "Unexpected Error"
                }
            } else {
                self?.status = .undetermined
                self?.message = GoogleCloudPlatform.loadErrorMessage ?? ""
            }

            callback(selfie)
        }
    }
}

class GoogleAppEngine: GoogleCloudPlatform {
    override var name: String { return "Google App Engine" }
}

class GoogleComputeEngine: GoogleCloudPlatform {
    override var name: String { return "Google Compute Engine" }
}

class GoogleCloudStorage: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Storage" }
}

class GoogleBigQuery: GoogleCloudPlatform {
    override var name: String { return "Google BigQuery" }
}

class GoogleCloudDataproc: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Dataproc" }
}

class GoogleCloudDatastore: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Datastore" }
}

class GoogleCloudDNS: GoogleCloudPlatform {
    override var name: String { return "Google Cloud DNS" }
}

class GoogleCloudPubSub: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Pub/Sub" }
}

class GoogleCloudSQL: GoogleCloudPlatform {
    override var name: String { return "Google Cloud SQL" }
}

class GoogleCloudDataflow: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Dataflow" }
}

class GoogleContainerEngine: GoogleCloudPlatform {
    override var name: String { return "Google Container Engine" }
}

class GoogleCloudConsole: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Console" }
}

class GoogleStackdriver: GoogleCloudPlatform {
    override var name: String { return "Google Stackdriver" }
}

class GoogleCloudBigtable: GoogleCloudPlatform {
    override var name: String { return "Google Cloud Bigtable" }
}
