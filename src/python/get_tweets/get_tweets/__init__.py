import argparse

import twitter


# In order to use the python-twitter API client, you will need to acquire a
# set of application tokens. These will be your consumer_key and consumer_secret
# Go to https://apps.twitter.com/ to create an app. In the Keys and Access Tokens
# tab of the Twitter Application page, you will see the access_token_key and
# access_token_secret.
# For more info: http://python-twitter.readthedocs.io/en/latest/getting_started.html
# These keys should NOT be in human-readable format in your app
consumer_key = ""
consumer_secret = ""
access_token_key = ""
access_token_secret = ""


class GetTweets:
    """Gets 300 tweets of a specific twitter user and returns them"""
    def __init__(self, twitter_user_name):
        self._tweets = self.get_tweets(twitter_user_name)

    @property
    def tweets(self):
        return self._tweets

    def get_tweets(self, twitter_user_name):
        """Uses the python-twitter API wrapper to get 300 tweets"""
        return_string = ""
        api = twitter.Api(consumer_key=consumer_key,
                          consumer_secret=consumer_secret,
                          access_token_key=access_token_key,
                          access_token_secret=access_token_secret)
        statuses = api.GetUserTimeline(screen_name=twitter_user_name, count=300)
        for status in statuses:
            status = status.AsDict()
            status_text = status.get("text")
            if status_text[0:2] != "RT":
                return_string += status_text

        return return_string

