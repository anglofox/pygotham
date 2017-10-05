from setuptools import setup, find_packages

setup(
    name='analyze_personality',
    version='0.0.1',
    description='An application that analyzes a twitter users personality based'
                ' on their tweets',
    long_description='This is a demo application created for pyGotham '
                     'to demonstrate how you can use Bazel and Pex to create '
                     'single Python executables for your Python software. The '
                     'application analyzes a twitter users personality based on '
                     'their tweets',
    url='https://github.com/anglofox/bazel-pex-rule',
    license='Apache-2.0',
    author='Angela Fox and Krish Chelikavada',
    author_email='angela@anglofox.com',
    classifiers=[
        'License :: OSI Approved :: Apache Software License',
        'Intended Audience :: Developers',
        'Programming Language :: Python',
        'Topic :: Internet :: WWW/HTTP'
    ],
    install_requires=[],
    packages=find_packages()
)