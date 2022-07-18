from setuptools import setup

setup(
    name='immutablex-starknet',
    version='0.2.1',
    description='Immutable X StarkNet Contracts',
    url='https://github.com/immutable/imx-starknet',
    author='Immutable',
    license='Apache-2.0',
    packages=['immutablex'],
    include_package_data=True,
    install_requires=[
        'openzeppelin-cairo-contracts',
        'cairolib'
    ],
)
