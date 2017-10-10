import argparse
import matplotlib.pyplot as plt
import requests

from get_tweets import GetTweets

# In order to use the Watson personality insights API, you will need a Watson
# username and password. www.ibm.com/watson/services/personality-insights/
# to learn more.
# Your password should NOT be in human-readable format in your app
watson_url = "https://gateway.watsonplatform.net/personality-insights/api"
watson_username = ""
watson_password = ""


class AnalyzePersonality:

    def go_through_category(self, category_name, category):
        categories = {}
        print(category_name)
        for trait in category:
            categories[trait.get("name")] = trait.get("percentile")
            print("{} - {}".format(trait.get("name"), trait.get("percentile")))
        return categories

    def analyze_personality(self, username):
        get_tweets = GetTweets(username)
        headers = {'Content-Type': 'text/plain;charset=utf-8', }
        params = (('version', '2016-10-20'),)\

        return_val = requests.post(
            watson_url + "/v3/profile",
            headers=headers,
            params=params,
            data=get_tweets.tweets.encode('utf-8'),
            auth=(watson_username, watson_password)
        )

        json_str = return_val.json()
        return json_str.get("needs"), json_str.get("personality"), json_str.get("values")
parser = argparse.ArgumentParser(add_help=False)
parser.add_argument('--help', action="help")
parser.add_argument(
    '-u', '--username',
    dest='username',
    metavar='',
    default='realdonaldtrump'
)
args = parser.parse_args()
analyzer = AnalyzePersonality()
traits = analyzer.analyze_personality(args.username)

needs = analyzer.go_through_category("NEEDS", traits[0])
print("_______________________________________")

personality = analyzer.go_through_category("PERSONALITY", traits[1])
print("_______________________________________")

values = analyzer.go_through_category("VALUES", traits[2])

