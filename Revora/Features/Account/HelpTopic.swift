import Foundation

/// A group of questions on the Help page. Keep the answers in step with the app: they name its
/// buttons and describe how it behaves.
nonisolated struct HelpTopic: Identifiable, Sendable {
    struct Question: Identifiable, Sendable {
        let question: LocalizedStringResource
        let answer: LocalizedStringResource

        var id: String { question.key }
    }

    let title: LocalizedStringResource
    let questions: [Question]

    var id: String { title.key }

    static let all: [HelpTopic] = [
        HelpTopic(title: "Recipes", questions: [
            Question(
                question: "How do I add a recipe?",
                answer: "Tap + at the top of Recipes, or New Recipe on Home. Only a title is needed, so you can fill in the rest later."
            ),
            Question(
                question: "How do I edit or delete a recipe?",
                answer: "Open the recipe and tap Edit. To delete it, tap Delete Recipe at the bottom of the recipe, or swipe left on it in Recipes. A deleted recipe and its photo can't be brought back."
            ),
            Question(
                question: "Can I split a recipe into parts?",
                answer: "Yes. In the editor, tap Add Section under Ingredients or Steps and give it a name, like \"For the filling\". Step sections are numbered, and the steps in each start again at 1."
            ),
            Question(
                question: "How do I add bullet points to a step?",
                answer: "While you're typing a step, tap the bullet list button above the keyboard. Press Return for the next bullet point, or Return on an empty one to move on to the next step."
            ),
            Question(
                question: "How do I move or remove ingredients and steps?",
                answer: "In the editor, drag a row by the handle on its right, even into another section. To remove one, tap the red minus button next to it. With VoiceOver, swipe up or down on a row to move or delete it."
            ),
            Question(
                question: "How do I add a photo?",
                answer: "In the editor, tap Add Photo at the top, then choose one from your library or take a new one. Photos are made smaller before they're saved, and details like where they were taken are removed."
            ),
            Question(
                question: "What are meal types for?",
                answer: "Mark a recipe as Breakfast, Lunch, Dinner, Snack, Dessert or Drink, as many as fit. Recipes can then show one meal at a time, and Home suggests recipes for the time of day."
            ),
        ]),
        HelpTopic(title: "Finding Recipes", questions: [
            Question(
                question: "How do I find a recipe quickly?",
                answer: "In Recipes, pull down on the list to search by title. Capitals and accents don't matter, so \"creme\" finds \"Crème Brûlée\". Tap a meal to see only those recipes, and tap it again to see them all."
            ),
            Question(
                question: "What's the difference between Recent, All and Favorites?",
                answer: "All shows every recipe from A to Z. Recent shows the ones you've opened in the last 3 days, newest first. Favorites shows the ones you've marked with a heart."
            ),
            Question(
                question: "How do I mark a favorite?",
                answer: "Tap the heart at the top of a recipe, or swipe right on it in Recipes. Do the same again to remove it."
            ),
            Question(
                question: "What does Surprise Me do?",
                answer: "It opens a random recipe for the time of day: breakfast in the morning, lunch in the afternoon, dinner in the evening and a snack late at night. If none of your recipes are marked for that meal, it picks from all of them. It shows up once you have two recipes."
            ),
            Question(
                question: "What's on Home?",
                answer: "Continue Cooking brings back the recipe you opened last. Below it are recipes for the current meal, your favorites, Rediscover for recipes you haven't opened in a month or more, and Browse by Meal."
            ),
        ]),
        HelpTopic(title: "Syncing & Offline", questions: [
            Question(
                question: "Are my recipes on all my devices?",
                answer: "Yes. Log in with the same account on your iPhone and iPad, and your recipes, favorites and photos are the same on both."
            ),
            Question(
                question: "Can I use Revora offline?",
                answer: "Yes. Recipes you've already seen open without a connection, and new recipes and edits are saved on your device, then synced once you're back online. Until then, Offline shows at the top of the screen. Logging in and changes to your account need a connection."
            ),
        ]),
        HelpTopic(title: "Your Account", questions: [
            Question(
                question: "Why do I need to confirm my email?",
                answer: "So your recipes are tied to an address you can get back into, like when you reset your password. After you create an account, we send a link to your email. Open it, then come back to Revora. If it doesn't arrive, tap Send a New Link."
            ),
            Question(
                question: "I forgot my password. What do I do?",
                answer: "On Log In, tap Forgot password? and enter your email. We'll send you a link to choose a new password."
            ),
            Question(
                question: "I didn't get an email from Revora.",
                answer: "Emails can take a few minutes, so check your spam or junk folder too, and make sure the address is spelled right. You can ask for a new link at any time."
            ),
            Question(
                question: "How do I change my name, email or password?",
                answer: "Go to Account. Your name is optional, and Home greets you with your first name. A new email needs confirming: we send a link to it, and once you open it, you log in again with the new email. Changing your password asks for your current one first."
            ),
            Question(
                question: "How do I switch between light and dark?",
                answer: "Go to Account and pick a Theme. System follows your device's setting, or choose Light or Dark."
            ),
            Question(
                question: "How do I delete my account?",
                answer: "Go to Account and tap Delete Account at the bottom, then enter your password. This permanently deletes your account and all of your recipes and photos, and it can't be undone."
            ),
        ]),
        HelpTopic(title: "Privacy", questions: [
            Question(
                question: "Who can see my recipes?",
                answer: "Only you. Your recipes and photos are private to your account."
            ),
            Question(
                question: "Does Revora show ads or track me?",
                answer: "No. There are no ads, analytics or tracking. The Privacy Policy in Account explains what Revora stores and why."
            ),
        ]),
    ]
}
