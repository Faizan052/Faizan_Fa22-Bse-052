import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const NewsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List articles = [];
  bool isLoading = true;
  String selectedCategory = 'world';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, IconData> categories = {
    'world': Icons.public,
    'business': Icons.business_center,
    'health': Icons.health_and_safety,
    'science': Icons.science,
    'technology': Icons.computer,
    'environment': Icons.eco,
    'education': Icons.school,
  };

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    const String apiKey = '7de9bdefbb5b48669c0962138ace1f07'; // your API key
    final String url =
        "https://newsapi.org/v2/top-headlines?country=us&category=$selectedCategory&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          articles = data['articles'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching news: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: buildDrawer(),
      appBar: AppBar(
        title: const Text('Daily Insight 📰'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? buildShimmer()
          : articles.isEmpty
          ? const Center(child: Text('No articles found'))
          : RefreshIndicator(
        onRefresh: fetchNews,
        child: AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                delay: const Duration(milliseconds: 100),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: buildNewsCard(article),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.pink],
              ),
            ),
            child: const Center(
              child: Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...categories.entries.map((entry) {
            return ListTile(
              leading: Icon(entry.value, color: Colors.blue),
              title: Text(entry.key.toUpperCase()),
              onTap: () {
                setState(() {
                  selectedCategory = entry.key;
                  isLoading = true;
                  Navigator.pop(context);
                  fetchNews();
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildNewsCard(dynamic article) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          article['urlToImage'] != null
              ? ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: CachedNetworkImage(
              imageUrl: article['urlToImage'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => buildImageShimmer(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          )
              : Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.pink],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Center(
              child: Text('No Image Available', style: TextStyle(color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  article['description'] ?? 'No Description',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      builder: (_) => buildBottomSheet(article['url']),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Read More'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomSheet(String url) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 200,
      child: Column(
        children: [
          const Text(
            "Open Full Article",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _launchURL(url),
            icon: const Icon(Icons.open_in_new),
            label: const Text("Open in Browser"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }
}
