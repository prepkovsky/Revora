import Foundation
import Testing
@testable import Revora

struct HelpTopicTests {
    /// The Help page tells rows apart by their text, so a repeat would confuse the list.
    @Test func topicsAndQuestionsAreUnique() {
        let topics = HelpTopic.all.map(\.id)
        let questions = HelpTopic.all.flatMap(\.questions).map(\.id)
        #expect(Set(topics).count == topics.count)
        #expect(Set(questions).count == questions.count)
    }

    @Test func everyTopicHasAnsweredQuestions() {
        for topic in HelpTopic.all {
            #expect(!topic.questions.isEmpty)
            for question in topic.questions {
                #expect(!String(localized: question.answer).isEmpty)
            }
        }
    }
}
