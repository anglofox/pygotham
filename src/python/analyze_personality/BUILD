load('//tools/build_rules:pex_rules.bzl', 'pex_binary')

pex_binary(
    name='analyze_personality',
    srcs=glob(['**']),
    deps=['//src/python/get_tweets'],
    reqs=['@analyze_personality//:requirements'],
    entry_point='analyze_personality'
)
