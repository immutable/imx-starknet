from setuptools import setup

setup(
    name='immutablex-starknet',
    version='0.1.0',
    description='Immutable X StarkNet Contracts',
    url='',
    author='Immutable',
    license='Apache-2.0',
    packages=['immutablex'],
    include_package_data=True,
    install_requires=[
        'openzeppelin-cairo-contracts',
    ],
)
