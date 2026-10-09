
- This is interesting

http://192.168.89.239/?feed=rss2

```xml
<rss version="2.0">
    <channel>
        <title>ColddBox</title>
        <atom:link href="http:///?feed=rss2" rel="self" type="application/rss+xml"/>
        <link/>
        <description>One more machine</description>
        <lastBuildDate>Mon, 19 Oct 2020 17:37:32 +0000</lastBuildDate>
        <language>en-GB</language>
        <sy:updatePeriod>hourly</sy:updatePeriod>
        <sy:updateFrequency>1</sy:updateFrequency>
        <generator>https://wordpress.org/?v=4.1.31</generator>
        <item>
            <title>The ColddBox is here</title>
            <link>/?p=1</link>
            <comments>/?p=1#comments</comments>
            <pubDate>Mon, 12 Oct 2020 15:06:57 +0000</pubDate>
            <dc:creator>the cold in person</dc:creator>
            <category>No category</category>
            <guid isPermaLink="false">http://10.0.2.9/?p=1</guid>
            <description>
            Welcome to ColddBox, a machine designed by C0ldd , it is a very simple machine to solve with several ways to escalate privileges, which serves to reinforce concepts, without further ado, good luck and enjoy!
            </description>
            <content:encoded>
            <p>Welcome to ColddBox, a machine designed by <a href="https://twitter.com/C0ldd__"> C0ldd </a>, it is a very simple machine to solve with several ways to escalate privileges, which serves to reinforce concepts, without further ado, good luck and enjoy!</p>
            </content:encoded>
            <wfw:commentRss>/?feed=rss2&p=1</wfw:commentRss>
            <slash:comments>1</slash:comments>
        </item>
    </channel>
</rss>
```

http://192.168.89.239/?feed=comments-rss2

```xml
<rss version="2.0">
    <channel>
        <title>Comments for ColddBox</title>
        <atom:link href="http:///?feed=comments-rss2" rel="self" type="application/rss+xml"/>
        <link/>
        <description>One more machine</description>
        <lastBuildDate>Thu, 24 Sep 2020 15:06:57 +0000</lastBuildDate>
        <sy:updatePeriod>hourly</sy:updatePeriod>
        <sy:updateFrequency>1</sy:updateFrequency>
        <generator>https://wordpress.org/?v=4.1.31</generator>
        <item>
            <title>Comment on The ColddBox is here by Sr Hott</title>
            <link>/?p=1#comment-1</link>
            <dc:creator>Sr Hott</dc:creator>
            <pubDate>Thu, 24 Sep 2020 15:06:57 +0000</pubDate>
            <guid isPermaLink="false">http://10.0.2.9/?p=1#comment-1</guid>
            <description>
                I like the machine, it offends me that it is cold inside. Long life to heat.
            </description>
            <content:encoded>
                <p>I like the machine, it offends me that it is cold inside. Long life to heat.</p>
            </content:encoded>
        </item>
    </channel>
</rss>
```

Scann users:

wpscan --url http://192.168.89.239/ --enumerate u 
